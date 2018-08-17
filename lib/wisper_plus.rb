require "wisper_plus/version"
require 'wisper_plus/railtie'
require 'wisper'

### ACTIVERECORD SUPPORT
module Wisper
  module ActiveRecord
    # ActiveRecord extension to automatically publish events for CRUD lifecycle
    # see https://github.com/krisleech/wisper/wiki/Rails-CRUD-with-ActiveRecord
    # see https://github.com/krisleech/wisper-activerecord
    module Publisher
      extend ActiveSupport::Concern
      include Wisper::Publisher

      included do
        after_commit :broadcast_create, on: :create
        after_commit :broadcast_update, on: :update
        after_commit :broadcast_destroy, on: :destroy
      end

      def broadcast(*args)
        super
      end
      alias publish broadcast

      protected

        # broadcast MODEL_created event to subscribed listeners
        def broadcast_create
          broadcast(:after_create, self)
        end

        # broadcast MODEL_updated event to subscribed listeners
        # pass the set of changes for background jobs to know what changed
        # see https://github.com/krisleech/wisper-activerecord/issues/17
        def broadcast_update
          broadcast(:after_update, self, previous_changes.with_indifferent_access) if previous_changes.any?
        end

        # broadcast MODEL_destroyed to subscribed listeners
        # pass a serialized version of the object attributes
        # for listeners since the object is no longer accessible in the database
        def broadcast_destroy
          broadcast(:after_destroy, attributes.with_indifferent_access)
        end
    end
  end

  ### ACTIVEJOB SUPPORT
  if defined?(ActiveJob)
    class ActiveJobBroadcaster
      def broadcast(subscriber, publisher, event, args)
        # Turn objects in args into GlobalID strings
        args = args.map { |e| e.respond_to?(:to_global_id) ? e.to_global_id.to_s : e }
        Wrapper.perform_later(subscriber.class.name, event, JSON.dump(args))
      end

      class Wrapper < ::ActiveJob::Base
        queue_as :default

        def perform(class_name, event, args)
          listener = class_name.constantize.new
          if listener.respond_to?(event)
            args = JSON.parse(args).map do |e|
              if e.is_a?(String) && e.starts_with?("gid://")
                begin
                  GlobalID::Locator.locate(e)
                rescue ActiveRecord::RecordNotFound
                  listener = nil
                end
              else
                e
              end
            end
            ap event
            listener&.public_send(event, *args)
          end
        end
      end

      def self.register
        Wisper.configure do |config|
          config.broadcaster :active_job, ActiveJobBroadcaster.new
          config.broadcaster :async,      ActiveJobBroadcaster.new
        end
      end
    end
  end

  Wisper::ActiveJobBroadcaster.register
end




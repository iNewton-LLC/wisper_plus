require 'rails'

class WisperPlus::Railtie < Rails::Railtie

  def self.subscribe(model_klass, subscriber_klass)
    model_class = model_klass
    if model_class != 'Global'
      begin
        model_class = model_class.constantize
        if !model_class.ancestors.include?(ApplicationRecord)
          # puts "🔸 #{model_class} is not an ActiveRecord model".yellow
          return
        end
        if !model_class.ancestors.include?(Wisper::Publisher)
          puts "🔸 #{model_class} is not including Wisper::ActiveRecord::Publisher. Cannot Subscribe #{subscriber_klass.magenta}.".yellow
          return
        end
      rescue NameError
        model_class = model_class.split("::")
        model_class.pop
        if model_class.size.positive?
          model_class = model_class.join('::')
          retry
        else
          puts "🔸 #{model_klass} not found"
          return
        end
      end
    end

    begin
      subscriber_klass = subscriber_klass.constantize
    rescue NameError
      puts "🔸 #{subscriber_klass} not found"
    end

    begin
      if model_class != 'Global'
        model_class.subscribe(subscriber_klass.new, async: false)
      else
        Wisper.subscribe(subscriber_klass.new)
      end
    rescue NoMethodError
      puts "🔸 #{model_class}.subscribe() not found"
    end

    if Rails.env.development?
      puts "🔹 #{subscriber_klass.to_s.magenta} => #{model_class.to_s.blue}"
    end
  end

  config.to_prepare do
    Wisper.clear if Rails.env.development?

    # AUTOLINK models to subscribers if DB exists
    if (::ActiveRecord::Base.connection rescue false)
      # Link any Models to their <Model>Subscriber class
      Dir.glob(Rails.root.join('app/subscribers/**/*.rb').to_s) do |filename|
        filename = filename.remove(Rails.root.join('app/subscribers/').to_s)[0..-4]
        subscriber_klass = filename.classify
        model_klass = subscriber_klass.chomp("Subscriber")
        WisperPlus::Railtie.subscribe(model_klass, subscriber_klass)

        subscribers_dir = Rails.root.join('app','subscribers',filename)
        if subscribers_dir.directory?
          subscribers_dir.each_child do |fpath|
            ap fpath
          end
        end
      end
    end
  end


end
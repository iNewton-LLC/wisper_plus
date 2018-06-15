require 'rails'

class WisperPlus::Railtie < Rails::Railtie

  intiailizer do
    # Link any Models to their <Model>Subscriber class
    Dir.glob(Rails.root.join('app/models/**/*.rb').to_s) do |filename|
      next if filename.index('/concerns/')
      filename = filename.remove(Rails.root.join('app/models/').to_s)[0..-4]
      klass = filename.camelize.constantize
      next unless klass.ancestors.include?(ApplicationRecord)
      begin
        notifier_klass = "#{klass}Subscriber".constantize
        klass.subscribe(notifier_klass.new, async: false)
        if Rails.env.development?
          puts "🔹 #{klass.to_s.magenta} #{'subscriber'.blue}"
        end
        if !klass.ancestors.include?(Wisper::Publisher)
          puts "🔸 #{klass} is not including Wisper::ActiveRecord::Publisher".yellow
        end
      rescue NameError
        # ignore
      end
    end
  end

end
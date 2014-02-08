require 'fileutils'

module Localeapp
  module Rails
    def self.initialize

      ActionController::Base.send(:include, Localeapp::Rails::Controller)

      if ::Rails::VERSION::MAJOR == 2 && ::Rails::VERSION::MINOR >= 3 # TODO: Check previous rails versions if required
        require 'localeapp/rails/2_3_translation_helper_monkeypatch'
      end

      # Rails >= 4.0.2 || Rails >= 3.2.16
      # ie: after CVE-2013-4491 patch (https://github.com/rails/rails/commit/78790e4bceedc632cb40f9597792d7e27234138a)
      if (::Rails::VERSION::MAJOR == 4 && (::Rails::VERSION::MINOR > 0 or (::Rails::VERSION::MINOR == 0 && ::Rails::VERSION::TINY >= 2))) or
         (::Rails::VERSION::MAJOR == 3 && (::Rails::VERSION::MINOR > 2 or (::Rails::VERSION::MINOR == 2 && ::Rails::VERSION::TINY >= 16)))
        require 'localeapp/rails/force_exception_handler_in_translation_helper'
        require 'localeapp/rails/mimic_rails_missing_translation_display'
      end

      Localeapp.configure do |config|
        config.logger                     = rails_logger
        config.environment_name           = rails_env
        config.project_root               = rails_root
        config.synchronization_data_file  = File.join([config.project_root, 'log', 'localeapp.yml'])
        config.translation_data_directory = File.join([config.project_root, 'config', 'locales'])
      end
      initialize_synchronization_data_file
    end

    def self.initialize_synchronization_data_file
      sync_file = Localeapp.configuration.synchronization_data_file
      if !File.exists?(sync_file)
        FileUtils.mkdir_p(File.dirname(sync_file))
        File.open(sync_file, 'w') do |f|
          f.write({:polled_at => Time.now.to_i, :updated_at => Time.now.to_i}.to_yaml)
        end
      end
    end

    protected

    def self.rails_logger
      if defined?(::Rails.logger)
        ::Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end
    end

    def self.rails_env
      if defined?(::Rails.env)
        ::Rails.env
      elsif defined?(RAILS_ENV)
        RAILS_ENV
      end
    end

    def self.rails_root
      if defined?(::Rails.root)
        ::Rails.root
      elsif defined?(RAILS_ROOT)
        RAILS_ROOT
      end
    end

  end
end

if defined?(Rails)
  require 'localeapp/rails/controller'
  require 'localeapp/exception_handler'
  Localeapp::Rails.initialize
  Localeapp.log('Loaded localeapp/rails')
end

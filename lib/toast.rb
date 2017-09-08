unless defined?(Rails)
  puts 'The Toast gem is made for Ruby on Rails 5.'
  exit 1
end

unless Rails::VERSION::MAJOR == 5
  puts 'Toast v1 requires Ruby on Rails 5, try v0.9 for older rails.'
  exit 1
end

require 'ostruct'
require 'toast/engine'
require 'toast/config_dsl'
require 'toast/rack_app'

module Toast
  Sym = "\xF0\x9F\x8D\x9E" # The BREAD

  # config data of all expose blocks
  @@expositions = []

  # collects all configs of one expose block (DSL methods write to it)
  @@current_expose = nil

  cattr_accessor :expositions, :settings

  class ConfigError < StandardError
  end

  # called once on boot via enigne.rb
  def self.init config_path='config/toast-api/*', settings_path='config/toast-api.rb'

    # clean up
    Toast.expositions.clear
    Toast.settings = nil

    settings = ''
    # read global settings
    if File.exists? settings_path
      open settings_path do |f|
        settings = f.read
      end
    else
      info "No global settings file found: `#{settings_path}', using defaults"
      settings_path = '[defaults]'
    end

    Toast::ConfigDSL.get_settings settings, settings_path

    # read configurations
    config_files = Dir[config_path]

    if config_files.empty?
      Toast.raise_config_error "No config files found in `#{config_path}`"
    else

      config_files.each do |fname|
        open fname do |f|
          config = f.read
          Toast::ConfigDSL.get_config(config, fname)
        end
      end
    end
  end

  def self.info str
    if Rails.const_defined?('Server') # only on console server
      puts Toast::Sym+'  Toast: '+str 
    end
  end

  def self.disable message=''
    info "Disabeling resource exposition due to config errors."
    info message unless message.blank?

    @@expositions.clear
  end

  def self.raise_config_error message
    raise ConfigError.new("CONFIG ERROR: #{message}")
  end

  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/toast.log")
  end

  # get the  representation (as Hash) by instance (w/o request)
  # base_uri must be passed to be prepended in URIs
  def self.represent instance, base_uri = ''

    # using RequestHelper#represent_one method with a mocked up object
    obj = Object.new
    class << obj
      include Toast::RequestHelpers
      attr_accessor :base_uri
    end
    obj.base_uri = base_uri
    obj.represent_one(instance, obj.get_config(instance.class) )
  end
end

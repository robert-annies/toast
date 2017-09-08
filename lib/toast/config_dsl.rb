module Toast
  module ConfigDSL

    # the currently process config file name
    mattr_accessor :cfg_name

    # traces the descent into the configuration, while gathering config items
    mattr_accessor :stack

    # Interprets one config file and stores config info in the @expositions Array using OpenStruct.
    #
    # Params:
    # +config+:: [String] The configuration file's content as string
    # +fname+::  [String] The file name of the config file with path relative to +Rails.root+
    #
    # Return: +nil+
    def self.get_config _toast_config, _toast_cfg_name

      # using _toast_ prefix for all locals here, because they end up in the
      # handler/allow block scope (closure)
      # also freeze them to prevent accidental changes
      # is there a way to remove closure vars with instance_eval?

      _toast_config.freeze
      _toast_cfg_name.freeze

      @@cfg_name = _toast_cfg_name
      @@stack    = []

      _toast_base = ConfigDSL::Base.new
      _toast_base.freeze
      _toast_base.instance_eval(_toast_config, _toast_cfg_name)

    rescue ArgumentError, NameError => _toast_error
      _toast_base.raise_config_error _toast_error.message
    end

    # Interprets the global settings file and stores data using OpenStruct
    # Params:
    # +config+:: [String] The configuration file's content as string
    # +fname+::  [String] The file name of the config file with path relative to +Rails.root+
    #
    # Return: +nil+
    def self.get_settings config, cfg_name
      @@cfg_name = cfg_name
      @@stack    = []

      # defaults
      Toast.settings = OpenStruct.new
      Toast.settings.max_window = 42
      Toast.settings.link_unlink_via_post = false
      Toast.settings.authenticate = lambda{|r| r}

      settings = ConfigDSL::Settings.new
      settings.instance_eval(config, cfg_name)

    rescue ArgumentError, NameError => error
      settings.raise_config_error error.message
    end
  end
end

require 'toast/config_dsl/common'
require 'toast/config_dsl/base'
require 'toast/config_dsl/expose'
require 'toast/config_dsl/association'
require 'toast/config_dsl/via_verb'
require 'toast/config_dsl/settings'

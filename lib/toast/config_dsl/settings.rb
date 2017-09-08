require 'toast/errors'

class Toast::ConfigDSL::Settings
  include Toast::ConfigDSL::Common

  class AuthenticateContext
    def fail_with hash
      raise Toast::Errors::CustomAuthFailure.new(hash)
    end
  end

  def toast_settings &block
    stack_push 'toast_settings' do
      self.instance_eval &block
    end
  end

  def max_window size
    if size.is_a?(Integer) and size > 0
      Toast.settings.max_window = size
    elsif size == :unlimited
      Toast.settings.max_window = 10**6 # yes that's inifinity 
    else
      raise_config_error 'max_window must a positive integer or :unlimited'
    end
  end

  def link_unlink_via_post boolean
    Toast.settings.link_unlink_via_post = boolean
  end

  def authenticate &block
    Toast.settings.authenticate = block
  end
end

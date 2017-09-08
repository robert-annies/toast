module Toast
  class Engine < Rails::Engine

    # configure our plugin on boot. other extension points such
    # as configuration, rake tasks, etc, are also available
    initializer "toast.initialize" do |app|

      # allow LINK and UNLINK methods
      if ActionDispatch::Request::HTTP_METHOD_LOOKUP['LINK'] == :link and
        ActionDispatch::Request::HTTP_METHOD_LOOKUP['UNLINK'] == :unlink
        Toast.info "INFO: LINK and UNLINK allowed by this Rails version: #{Rails.version}"
      else
        ActionDispatch::Request::HTTP_METHOD_LOOKUP['LINK'] = :link
        ActionDispatch::Request::HTTP_METHOD_LOOKUP['UNLINK'] = :unlink
      end

      # for LINK/UNLINK via POST and x-http-method-override header
      app.middleware.unshift Rack::MethodOverride

      # skip init if in test mode: Toast.init should be called in each test
      unless Rails.env == 'test'
        begin
          Toast.info 'Loading Toast'
          Toast.init
          Toast.info "Exposed model classes: #{Toast.expositions.map{|e| e.model_class.name}.join(' ')}"

        rescue Toast::ConfigError => error
          error.message.split("\n").each do |line|
            Toast.info line
          end
          Toast.disable
        end
      end
    end
  end
end

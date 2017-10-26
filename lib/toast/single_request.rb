require 'toast/request_helpers'

class Toast::SingleRequest
  include Toast::RequestHelpers
  include Toast::Errors

  def initialize  config, base_config, auth, request
    @config      = config
    @base_config = base_config
    @selected_attributes = request.query_parameters[:toast_select].try(:split,/ *, */)
    @uri_params  = request.query_parameters
    @base_uri    = base_uri(request)
    @verb        = request.request_method.downcase
    @auth        = auth
    @path        = request.path_parameters[:toast_path]#.split('/')
    @request     = request
  end

  def respond

    if @config.via_get.nil?
      # not declared
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "GET not configured"
    else
      begin
        model = call_handler(@config.via_get.handler, @uri_params)
        call_allow(@config.via_get.permissions, @auth, model, @uri_params)

        case model
        when @base_config.model_class
          response :ok,
                   headers: {"Content-Type" => @base_config.media_type},
                   body:    represent(model, @base_config)
        when nil
          response :not_found, msg: "resource not found at /#{@path}"
        else
          # wrong class/model_class
          response :internal_server_error,
                   msg: "single method returned `#{model.class}', expected `#{@base_config.model_class}'"
        end

      rescue ActiveRecord::RecordNotFound => error
        response :not_found, msg: error.message

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue => error
        return response :internal_server_error,
                        msg: "exception raised: #{error} \n#{error.backtrace[0..5].join("\n")}"
      end
    end
  end
end

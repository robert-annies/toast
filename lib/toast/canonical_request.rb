require 'toast/request_helpers'

class Toast::CanonicalRequest
  include Toast::RequestHelpers
  include Toast::Errors

  def initialize id, base_config, auth, request
    @id          = id
    @base_config = base_config
    @selected_attributes = request.query_parameters[:toast_select].try(:split,/ *, */)
    @uri_params  = request.query_parameters
    @base_uri    = base_uri(request)
    @verb        = request.request_method.downcase
    @auth        = auth
    @request     = request
  end

  def respond
    if @verb.in? %w(get patch put delete)
      self.send(@verb)
    else
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@base_config)},
               msg: "method #{@verb.upcase} not supported for collection URIs"
    end
  end


  private
  def get
    if @base_config.via_get.nil?
      # not declared under expose {}
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@base_config)},
               msg: "GET not configured"
    else
      begin
        model_instance = @base_config.model_class.find(@id)

        # call allow blocks to authorize
        call_allow @base_config.via_get.permissions, @auth, model_instance, @uri_params

        model_instance = call_handler(@base_config.via_get.handler, model_instance, @uri_params)

        response :ok,
                 headers: {"Content-Type" => @base_config.media_type},
                 msg: "sent #{model_instance.class}##{model_instance.id}",
                 body: represent(model_instance, @base_config)

      rescue ActiveRecord::RecordNotFound
        response :not_found, msg: "#{@base_config.model_class}##{@id} not found"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue AllowError => error
        response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"
      rescue HandlerError => error
        response :internal_server_error,
                        msg: "exception raised in via_get handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue => error
        response :internal_server_error, msg: "exception from via_get handler: " + error.message
      end
    end
  end

  def put
    patch
  end

  def patch
    if @base_config.via_patch.nil?
      # not declared under expose {}
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@base_config)},
               msg: "PATCH not configured"
    else
      begin
        # decode payload
        payload  = JSON.parse(@request.body.read)

        # remove all attributes not in writables from payload
        payload.delete_if do |attr,val|
          unless attr.to_sym.in?(@base_config.writables)
            Toast.logger.warn "<PATCH #{@request.fullpath}> received attribute `#{attr}' is not writable or unknown"
            true
          end
        end

        model_instance = @base_config.model_class.find(@id)
        call_allow(@base_config.via_patch.permissions,
                   @auth, model_instance, @uri_params)

        if call_handler(@base_config.via_patch.handler,
                        model_instance, payload, @uri_params)

          response :ok, headers: {"Content-Type" => @base_config.media_type},
                   msg: "updated #{@base_config.model_class}##{@id}",
                   body: represent(@base_config.model_class.find(@id), @base_config)

        else
          message = model_instance.errors.count > 0 ?
                      ": " + model_instance.errors.full_messages.join(',') : ''

          response :conflict,
                   msg: "patch of #{model_instance.class}##{model_instance.id} aborted#{message}"
        end

      rescue JSON::ParserError => error
        response :internal_server_error, msg: "expect JSON body"

      rescue ActiveRecord::RecordNotFound => error
        response :not_found, msg: error.message

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue AllowError => error
        response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"
      rescue HandlerError => error
        response :internal_server_error,
                        msg: "exception raised in via_patch handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue => error
        response :internal_server_error, msg: "exception from via_patch handler: "+ error.message
      end
    end
  end

  def delete
    if @base_config.via_delete.nil?
      # not declared
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@base_config)},
               msg: "DELETE not configured"
    else
      begin

        model_instance = @base_config.model_class.find(@id)

        call_allow(@base_config.via_delete.permissions,
                   @auth, model_instance, @uri_params)

        if call_handler(@base_config.via_delete.handler,
                        model_instance, @uri_params)
          response :no_content, msg: "deleted #{@base_config.model_class}##{@id}"
        else

          message = model_instance.errors.count > 0 ?
                      ": " + model_instance.errors.full_messages.join(',') : ''

          response :conflict,
                   msg: "deletion of #{model_instance.class}##{model_instance.id} aborted#{message}"
        end

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

      rescue ActiveRecord::RecordNotFound => error
        response :not_found,
                 msg: error.message

      rescue => error
        response :internal_server_error,
                 msg: "exception from via_delete handler: #{error.message}"
      end
    end
  end
end

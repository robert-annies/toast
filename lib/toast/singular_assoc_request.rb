require 'toast/request_helpers'
require 'link_header'

class Toast::SingularAssocRequest
  include Toast::RequestHelpers
  include Toast::Errors

  def initialize  id, config, base_config, auth, request
    @id          = id
    @config      = config
    @base_config = base_config
    @selected_attributes = request.query_parameters[:toast_select].try(:split,/ *, */)
    @uri_params  = request.query_parameters
    @base_uri    = base_uri(request)
    @verb        = request.request_method.downcase
    @auth        = auth
    @request     = request
  end

  def respond
    if @verb.in? %w(get link unlink)
      self.send(@verb)
    else
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "#{@verb.upcase} not supported for singular association requests"
    end
  end

  private

  def get
    if @config.via_get.nil?
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "GET not configured"
    else
      begin
        source = @base_config.model_class.find(@id)
        target_config = get_config(@config.target_model_class)
        model_instance = @config.via_get.handler.call(source, @uri_params)
        call_allow(@config.via_get.permissions, @auth, source, @uri_params)

        unless model_instance.is_a? @config.target_model_class
          # wrong class
          response :internal_server_error,
                   msg: "singular association returned `#{model_instance.class}', expected `#{@config.target_model_class}'"
        else

          response :ok,
                   headers: {"Content-Type" => @config.media_type},
                   body: represent(model_instance, target_config),
                   msg: "sent ##{@config.model_class}##{@id}"
        end

      rescue NotAllowed => error
        return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"


      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_get handler: `#{error.orig_error.message}' in #{error.source_location}"

      rescue ActiveRecord::RecordNotFound
        response :not_found,
                 msg: "#{@config.model_class.name}##{@config.assoc_name} not found"

      rescue ConfigNotFound => error
        response :internal_server_error,
                 msg: "no API configuration found for model `#{@config.target_model_class.name}'"

      rescue => error
        response :internal_server_error,
                 msg: "exception from via_get handler: #{error.message}"
      end
    end
  end

  def link
    if @config.via_link.nil?
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "LINK not configured"
    else

      begin
        source = @base_config.model_class.find(@id)
        begin

          call_allow(@config.via_link.permissions, @auth, source, @uri_params)


          link = LinkHeader.parse(@request.headers['Link']).find_link(['ref','related'])

          if link.nil?
            return response :bad_request, msg: "Link header missing or invalid"
          end

          name, target_id = URI(link.href).path.split('/')[1..-1]
          target_model_class = name.singularize.classify.constantize

          unless is_active_record? target_model_class
            return response :not_found, msg: "target class `#{target_model_class.name}' is not an `ActiveRecord'"
          end

          if  target_model_class != @config.target_model_class
            return response :bad_request,
                            msg: "target class `#{target_model_class.name}' invalid, expect: `#{@config.target_model_class}'"
          end

          @config.via_link.handler.call(source, target_model_class.find(target_id), @uri_params)
          response :ok,
                   msg: "linked #{source.class}##{source.id} with #{target_model_class.name}##{@id}"

        rescue NotAllowed => error
          return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

        rescue BadRequest => error
          response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

        rescue HandlerError => error
          return response :internal_server_error,
                          msg: "exception raised in via_link handler: `#{error.orig_error.message}' in #{error.source_location}"

        rescue ActiveRecord::RecordNotFound # target not found
          response :not_found, msg: "#{target_model_class.name}##{target_id} not found"

        rescue => error
          response :internal_server_error, msg: "exception from via_link handler: #{error.message}"
        end
      rescue ActiveRecord::RecordNotFound # source not found
        response :not_found, msg: "#{@base_config.model_class.name}##{@id} not found"
      end
    end

  end

  def unlink
    if @config.via_unlink.nil?
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "UNLINK not configured"
    else
      begin
        source = @base_config.model_class.find(@id)
        call_allow(@config.via_unlink.permissions, @auth, source, @uri_params)

        link = LinkHeader.parse(@request.headers['Link']).find_link(['ref','related'])

        if link.nil?
          return response :bad_request, msg: "Link header missing or invalid"
        end

        name, target_id = URI(link.href).path.split('/')[1..-1]
        target_model_class = name.singularize.classify.constantize

        unless is_active_record? target_model_class
          return response :not_found, msg: "target class `#{target_model_class.name}' is not an `ActiveRecord'"
        end

        if target_model_class != @config.target_model_class
          return response :bad_request,
                          msg: "target class `#{target_model_class.name}' invalid, expect: `#{@config.target_model_class}'"
        end

        target = nil
        begin
          target = target_model_class.find(target_id)
        rescue ActiveRecord::RecordNotFound # target
          return response :not_found, msg: "#{target_model_class.name}##{target_id} not found"
        end

        current = source.send(@config.assoc_name)

        if current != target
          return response :conflict, msg: "target `#{current.class}##{current.id}' is not associated, cannot unlink `#{target.class}##{target.id}'"
        end

        call_handler(@config.via_unlink.handler, source, target, @uri_params)

        response :ok,
                 msg: "unlinked #{source.class}##{source.id} from #{target_model_class.name}##{target_id}"

      rescue NotAllowed => error
        return response :unauthorized,
                        msg: "not authorized by allow block in: #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_unlink handler: `#{error.orig_error.message}' in #{error.source_location}"

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"

      rescue ActiveRecord::RecordNotFound # source
        return response :not_found, msg: "#{@base_config.model_class.name}##{@id} not found"
      end
    end
  end
end

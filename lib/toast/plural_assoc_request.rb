require 'toast/request_helpers'
require 'toast/http_range'
require 'link_header'

class Toast::PluralAssocRequest
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
    if @verb.in? %w(get post link unlink)
      self.send(@verb)
    else
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "method #{@verb.upcase} not supported for association URIs"
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

        target_config = get_config(@config.target_model_class)

        requested_range = Toast::HttpRange.new(@request.env['HTTP_RANGE'])

        range_start = requested_range.start
        window      = if (requested_range.size.nil? || requested_range.size > @config.max_window)
                        @config.max_window
                      else
                        requested_range.size
                      end

        source = @base_config.model_class.find(@id) # may raise ActiveRecord::RecordNotFound
        relation = call_handler(@config.via_get.handler, source, @uri_params) # may raise HandlerError

        unless relation.is_a? ActiveRecord::Relation and relation.model == @config.target_model_class
          return response :internal_server_error,
                          msg: "plural association handler returned `#{relation.class}', expected `ActiveRecord::Relation' (#{@config.target_model_class})"
        end

        call_allow(@config.via_get.permissions, @auth, source, @uri_params) # may raise NotAllowed, AllowError


        # count = relation.count doesn't always work
        # fix problematic select extensions for counting (-> { select(...) })
        # this fails if the where clause depends on the the extended select
        count = relation.count_by_sql relation.to_sql.sub(/SELECT.+FROM/,'SELECT COUNT(*) FROM')
        headers = {"Content-Type" => @config.media_type}

        if count > 0
          range_end = if (range_start + window - 1) > (count - 1) # behind last
                      count - 1
                    else
                      (range_start + window - 1)
                    end

          headers[ "Content-Range"] = "items=#{range_start}-#{range_end}/#{count}"
        end

        response :ok,
                 headers: headers,
                 body: represent(relation.limit(window).offset(range_start), target_config),
                 msg: "sent #{count} of #{target_config.model_class}"


      rescue  ActiveRecord::RecordNotFound
        return response :not_found,
                        msg: "#{@config.model_class.name}##{@config.assoc_name} not found"

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_get handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue ConfigNotFound => error
        return response :internal_server_error,
                        msg: "no API configuration found for model `#{@config.target_model_class.name}'"

      rescue => error
        return response :internal_server_error,
                        msg: "exception raised: #{error} \n#{error.backtrace[0..5].join("\n")}"
      end
    end
  end

  def post
    if @config.via_post.nil?
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "POST not configured"
    else
      begin
        payload  = JSON.parse(@request.body.read)
        target_config = get_config(@config.target_model_class)

        # remove all attributes not in writables from payload
        payload.delete_if do |attr,val|
          unless attr.to_sym.in?(target_config.writables)
            Toast.logger.warn "<POST #{@request.fullpath}> received attribute `#{attr}' is not writable or unknown"
            true
          end
        end

        source = @config.base_model_class.find(@id)

        call_allow(@config.via_post.permissions,
                   @auth, source, @uri_params)

        new_instance = call_handler(@config.via_post.handler,
                                    source, payload, @uri_params)

        if new_instance.persisted?
          response :created,
                   headers: {"Content-Type" => target_config.media_type},
                   body: represent(new_instance, target_config ),
                   msg: "created #{new_instance.class}##{new_instance.id}"
        else
          message = new_instance.errors.count > 0 ?
                      ": " + new_instance.errors.full_messages.join(',') : ''

          response :conflict,
                   msg: "creation of #{new_instance.class} aborted#{message}"
        end

      rescue ActiveRecord::RecordNotFound
        response :not_found, msg: "#{@config.base_model_class.name}##{@id} not found"

      rescue JSON::ParserError => error
        return response :internal_server_error, msg: "expect JSON body"

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_post handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        return response :unauthorized,
                        msg: "not authorized by allow block in: #{error.source_location}"

      rescue ConfigNotFound => error
        return response :internal_server_error,
                        msg: "no API configuration found for model `#{@config.target_model_class.name}'"

      rescue => error
        return response :internal_server_error,
                        msg: "exception raised: #{error} \n#{error.backtrace[0..5].join("\n")}"
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
        link = LinkHeader.parse(@request.headers['Link']).find_link(['rel','related'])

        if link.nil? or URI(link.href).path.nil?
          return response :bad_request, msg: "Link header missing or invalid"
        end

        name, target_id = split_link_header(link)
        target_model_class = name.singularize.classify.constantize

        unless is_active_record? target_model_class
          return response :not_found, msg: "target class `#{target_model_class.name}' is not an `ActiveRecord'"
        end

        target = target_model_class.find(target_id)

        call_allow(@config.via_link.permissions, @auth, source, @uri_params)
        call_handler(@config.via_link.handler, source, target, @uri_params)

        response :ok,
                 msg: "linked #{target_model_class.name}##{@id} with #{source.class}##{source.id}.#{@config.assoc_name}",
                 body: Toast.settings.link_unlink_via_post ? '' : nil

      rescue ActiveRecord::RecordNotFound => error
        response :not_found, msg: error.message

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"
      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_link handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue => error
        response :internal_server_error,
                 msg: "exception from via_link handler #{error.message}"
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
        link = LinkHeader.parse(@request.headers['Link']).find_link(['rel','related'])

        if link.nil? or URI(link.href).nil?
          return response :bad_request, msg: "Link header missing or invalid"
        end

        name, id = split_link_header(link)
        target_model_class = name.singularize.classify.constantize

        unless is_active_record? target_model_class
          return response :not_found, msg: "target class `#{target_model_class.name}' is not an `ActiveRecord'"
        end

        call_allow(@config.via_unlink.permissions, @auth, source, @uri_params)
        call_handler(@config.via_unlink.handler, source, target_model_class.find(id), @uri_params)

        response :ok,
                 msg: "unlinked #{target_model_class.name}##{id} from #{source.class}##{source.id}.#{@config.assoc_name}",
                 body: Toast.settings.link_unlink_via_post ? '' : nil

      rescue ActiveRecord::RecordNotFound => error
        response :not_found, msg: error.message

      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}"

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_unlink handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue NotAllowed => error
        return response :unauthorized, msg: "not authorized by allow block in: #{error.source_location}"

      rescue => error
        response :internal_server_error,
                 msg: "exception from via_unlink handler: " + error.message

      end
    end
  end
end

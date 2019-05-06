require 'toast/request_helpers'
require 'toast/http_range'

class Toast::CollectionRequest
  include Toast::RequestHelpers
  include Toast::Errors

  def initialize config, base_config, auth, request
    @config          = config
    @base_config     = base_config
    @base_uri        = base_uri(request)
    @verb            = request.request_method.downcase
    @requested_range = Toast::HttpRange.new(request.env['HTTP_RANGE'])
    @selected_attributes = request.query_parameters[:toast_select].try(:split,/ *, */)
    @uri_params      = request.query_parameters
    @auth            = auth
    @request         = request
  end

  def respond
    if @verb.in? %w(get post)
      self.send(@verb)
    else
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@base_config)},
               msg: "method #{@verb.upcase} not supported for collection URIs"
    end
  end

  private
  def get
    if @config.via_get.nil?
      # not declared
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "GET not configured"
    else
      begin

        range_start = @requested_range.start
        window      = if (@requested_range.size.nil? || @requested_range.size > @config.max_window)
                        @config.max_window
                      else
                        @requested_range.size
                      end

        relation    = call_handler(@config.via_get.handler, @uri_params)
        call_allow(@config.via_get.permissions,
                    @auth, relation, @uri_params)

        if relation.is_a?(ActiveRecord::Relation) and
          relation.model.name == @config.base_model_class.name

          result = relation.limit(window).offset(range_start)

          # count = relation.count doesn't always work
          # fix problematic select extensions for counting (-> { select(...) })
          # this fails if the where clause depends on the the extended select
          count = relation.count_by_sql relation.to_sql.sub(/SELECT.+FROM/,'SELECT COUNT(*) FROM')
          headers = {"Content-Type" => @config.media_type}

          if count > 0
            headers["Content-Range"] = "items=#{range_start}-#{range_start + result.length - 1}/#{count}"
          end

          response :ok,
                   headers: headers,
                   body: represent(result, @base_config),
                   msg: "sent #{result.length} records of #{@base_config.model_class}"

        else
          # wrong class/model_class
          response :internal_server_error,
                   msg: "collection method returned #{relation.class}, expected ActiveRecord::Relation of #{@config.base_model_class}"
        end


      rescue NotAllowed => error
        return response :unauthorized,
                        msg: "not authorized by allow block in: #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}",
                  headers: {'X-Toast-Error' => error.code}

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_get handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"
      rescue => error
        response :internal_server_error,
                 msg: "exception from via_get handler in: #{error.backtrace.first.sub(Rails.root.to_s+'/', '')}: #{error.message}"
      end
    end
  end

  def post
    if @config.via_post.nil?
      # not declared
      response :method_not_allowed,
               headers: {'Allow' => allowed_methods(@config)},
               msg: "POST not configured"
    else
      begin
        payload  = JSON.parse(@request.body.read)

        call_allow(@config.via_post.permissions,
                   @auth, nil, @uri_params)

        # remove all attributes not in writables from payload
        payload.delete_if do |attr,val|
          unless attr.to_sym.in?(@base_config.writables)
            Toast.logger.warn "<POST #{@request.fullpath}> received attribute `#{attr}' is not writable or unknown"
            true
          end
        end

        new_instance = call_handler(@config.via_post.handler, payload, @uri_params)

        if new_instance.persisted?
          response :created,
                   headers: {"Content-Type" => @base_config.media_type},
                   msg: "created #{new_instance.class}##{new_instance.id}",
                   body: represent(new_instance, @base_config)
        else
          message = new_instance.errors.count > 0 ?
                      ": " + new_instance.errors.full_messages.join(',') : ''

          response :conflict,
                   msg: "creation of #{new_instance.class} aborted#{message}"
        end

      rescue JSON::ParserError => error
        return response :internal_server_error, msg: "expect JSON body"

      rescue NotAllowed => error
        return response :unauthorized,
                        msg: "not authorized by allow block in: #{error.source_location}"

      rescue BadRequest => error
        response :bad_request, msg: "`#{error.message}' in: #{error.source_location}",
                  headers: {'X-Toast-Error' => error.code}

      rescue HandlerError => error
        return response :internal_server_error,
                        msg: "exception raised in via_post handler: `#{error.orig_error.message}' in #{error.source_location}"
      rescue AllowError => error
        return response :internal_server_error,
                        msg: "exception raised in allow block: `#{error.orig_error.message}' in #{error.source_location}"
      rescue => error
        response :internal_server_error,
                 msg: "exception from via_post handler in: #{error.backtrace.first.sub(Rails.root.to_s+'/', '')}: #{error.message}"

      end
    end
  end
end

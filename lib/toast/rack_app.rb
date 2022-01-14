require 'toast/collection_request'
require 'toast/canonical_request'
require 'toast/single_request'
require 'toast/singular_assoc_request'
require 'toast/plural_assoc_request'
require 'toast/errors'

class Toast::RackApp
  # NOTE: the RackApp object is shared in threads of concurrent requests
  #       (e.g. when using Puma server, but not in Passenger (single-threded, multi-process)).
  #       Anyays, don't use any instance vars (@ variables in #call).
  #       It causes chaos

  include Toast::RequestHelpers

  def call(env)

    request = ActionDispatch::Request.new(env)
    Toast.request = request

    Toast.logger.info "processing: <#{request.method} #{CGI.unescape(request.fullpath)}>"

    # Authentication: respond with 401 on exception or falsy return value:
    begin
      unless (auth = Toast::ConfigDSL::Settings::AuthenticateContext.new.
                      instance_exec(request, &Toast.settings.authenticate))
         return response :unauthorized, msg: "authentication failed"
      end
    rescue Toast::Errors::CustomAuthFailure => caf
      return response(caf.response_data[:status] || :unauthorized,
               msg: caf.response_data[:body],
               headers: caf.response_data[:headers])
    rescue => error
      return response :unauthorized, msg: "authentication failed: `#{error.message}'"
    end

    path       = request.path_parameters[:toast_path].split('/')

    # look up requested model
    model_class = resolve_model(path, Toast.path_tree)

    if model_class.nil?
      return response :not_found,
                      msg: "no API configuration found for endpoint /#{path.join('/')}"
    end

    # select base configuration
    base_config = get_config(model_class)

    # remove path prefix
    path = path[(base_config.prefix_path.length)..-1]

    toast_request =
      case path.length
      when 1 # root collection: /apples

        if base_config.collections[:all].nil?
          return response :not_found, msg: "collection `/#{path[0]}' not configured"
        else
          # root collection
          Toast::CollectionRequest.new( base_config.collections[:all],
                                        base_config,
                                        auth,
                                        request)
        end
      when 2 # canonical, single or collection: /apples/10 , /apples/first, /apples/red_ones
        if path.second =~ /\A\d+\z/
          Toast::CanonicalRequest.new( path.second.to_i,
                                       base_config,
                                       auth,
                                       request )
        else
          if col_config = base_config.collections[path.second.to_sym]
            Toast::CollectionRequest.new(col_config,
                                         base_config,
                                         auth,
                                         request)

          elsif sin_config = base_config.singles[path.second.to_sym]
            Toast::SingleRequest.new(sin_config,
                                     base_config,
                                     auth,
                                     request)
          else
            return response :not_found,
                            msg: "collection or single `#{path.second}' not configured in: #{base_config.source_location}"
          end
        end

      when 3 # association: /apples/10/tree, /tree/5/apples

        if assoc_config = base_config.associations[path.third.to_sym]
          if assoc_config.singular

            Toast::SingularAssocRequest.new( path.second.to_i,
                                             assoc_config,
                                             base_config,
                                             auth,
                                             request )

          else
            # process_plural_association assoc_config, path.second.to_i
            Toast::PluralAssocRequest.new( path.second.to_i,
                                           assoc_config,
                                           base_config,
                                           auth,
                                           request )
          end
        else
          return response :not_found,
                          msg: "association `#{model_class.name}##{path.third}' not configured"
        end

      else
        return response :not_found,
                        msg: "#{request.url} not found (invalid path)"
      end

    toast_request.respond

  end

  private
    # gets the model class from the
    # it's similar to Hash#dig but stops at a non string
    def resolve_model path, path_tree
      if path_tree[ path.first ].is_a?(Hash)
        # dig deeper
        resolve_model(path[1..-1], path_tree[ path.first ])
      else
        path_tree[ path.first ]
      end
    end
end


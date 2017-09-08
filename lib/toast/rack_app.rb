require 'rack/accept_media_types'
class Toast::ConfigNotFound < StandardError; end
class Toast::RackApp
  def call(env)

    @path       = env["action_dispatch.request.path_parameters"][:toast_path].split('/')
    @verb       = env["REQUEST_METHOD"].downcase
    @uri_params = env["QUERY_STRING"]
    @base_uri   = env['rack.url_scheme'] + '://' +
                  env['HTTP_HOST']  # + name space

    # strip path prefixes

    # check model
    begin
      @model = @path.first.singularize.classify.constantize
      raise NameError unless @model.descends_from_active_record?
    rescue NameError
      raise ActionController::RoutingError.new("No route matches: #{env["action_dispatch.request.path_parameters"][:toast_path]}")
    end

    # select base configuration
    @preferred_type = Rack::AcceptMediaTypes.new(env['HTTP_ACCEPT']).prefered || "application/json"
    @base_config = get_config(@model)

    case @path.length
    when 2
      if @path.second =~ /\A\d+\z/
        process_canonical @path.second.to_i
      else
        if col_config = @base_config.collections[@path.second.to_sym]
          process_collection col_config
        elsif sin_config = @base_config.singles[@path.second.to_sym]
          process_single sin_config
        else
          raise "collection or single #{@path.second} not configured"
        end
      end

    when 3 # association
      if assoc_config = @base_config.associations[@path.third.to_sym]
        if assoc_config.singular
          process_singular_association assoc_config, @path.second.to_i
        else
          process_plural_association assoc_config, @path.second.to_i
        end
      else
        raise "association  #{@model.name}##{@path.third} not configured"
      end

    else
      nil
    end
  end

  def get_config model
    Toast.expositions.detect do |exp|
      exp.model == model
    end || raise(Toast::ConfigNotFound)
  end

  def process_single config
    begin
      model_instance = config.via_get.handler.call(@model, @uri_params)
    rescue ActiveRecord::RecordNotFound
      [404, {}, ["Toast: resource #{@model}#{@base_config.name} not found"]]
    rescue => error
      [500, {}, ["Toast: excpetion from via_get handler", error.message]]
    end

    [200, {"Content-Type" => @base_config.media_type}, [represent(model_instance, @base_config)]]
  end

  def process_collection config
    begin
      model_instances = config.via_get.handler.call(@uri_params)
    rescue => error
      [500, {}, ["Toast: exception from via_get handler", error.message]]
    end

    [200, {"Content-Type" => config.media_type}, [represent(model_instances, @base_config)]]
  end

  def process_canonical id
    if @base_config.via_get.nil?
      # no declared under expose {}
      [404, {}, ["Toast: GET not configured"]]
    else
      begin
        model_instance = @base_config.via_get.handler.call(@model.find(id), @uri_params)
      rescue ActiveRecord::RecordNotFound
        [404, {}, ["Toast: #{@model}##{@base_config.name} not found"]]
      rescue => error
        [500, {}, ["Toast: exception from via_get handler", error.message]]
      end
      [200, {"Content-Type" => @base_config.media_type}, [represent(model_instance, @base_config)]]
    end
  end

  def process_plural_association config, id
    if config.via_get.nil?
      [404, {}, ["Toast: GET not configured"]]
    else
      begin
        target_config = get_config(config.target_model)
        relation = config.via_get.handler.call(@model.find(id).send(config.assoc_name.to_sym), @uri_params)
        [200, {"Content-Type" => config.media_type}, [represent(relation, target_config )]]

      rescue ActiveRecord::RecordNotFound
        [404, {}, ["Toast: #{@model.name}##{config.assoc_name} not found"]]
      rescue Toast::ConfigNotFound => e
        [404, {}, ["Toast: #{@model.name}##{config.assoc_name} not representable as `#{e.message}'"]]
      rescue => error
        [500, {}, ["Toast: exception from via_get handler", error.message]]
      end
    end
  end


  def represent_one record, config
    result = {}
    (config.readables + config.writables).each do |attr|
      result[attr] = record[attr.to_s]
    end

    result['self'] = "#{@base_uri}/#{record.class.name.underscore.pluralize}/#{record.id}"

    # add associations
    config.associations.each do |name, config|
      result[name] = "#{result['self']}/#{name}"
    end
    result
  end

  def represent record_or_enum, config
    result = if record_or_enum.is_a? Enumerable
               record_or_enum.map do |record|
                 represent_one(record, config)
               end
             else
               represent_one(record_or_enum, config)
             end

    result.to_json
  end
end

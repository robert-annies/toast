module Toast

  # A Single resource is queried without an ID, by custom class methods
  # or scopes of the model or ActiveRecord single finders like:
  # first, last

  # The single resource name must be a class method of the model and
  # must return nil or an instance.

  # GET is the only allowed verb. To make changes the URI with ID has
  # to be used.
  class Single < Resource

    attr_reader :model

    def initialize model, subresource_name, params, config_in, config_out
      @config_in = config_in
      @config_out = config_out

      unless @config_out.singles.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @params = params
      @format = params[:format]


      @record = if @config_out.pass_params_to.include?(subresource_name)
                  @model.send(subresource_name, @params)
                else
                  @model.send(subresource_name)
                end
      
      raise ResourceNotFound if @record.nil?      
    end

    def get
      case @format
      when "html"
        {
          :template => "resources/#{model.to_s.underscore}",
          :locals => { model.to_s.pluralize.underscore.to_sym => @record }
        }
      when "json"
        {
          :json => @record.represent( @config_out.exposed_attributes,
                                      @config_out.exposed_associations,
                                      @base_uri ),
          :status => :ok
        }
      else
        raise ResourceNotFound
      end
    end


    def put
      raise MethodNotAllowed
    end

    def post payload
      raise MethodNotAllowed
    end

    def delete
      raise MethodNotAllowed
    end
  end
end

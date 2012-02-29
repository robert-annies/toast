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
    
    def initialize model, subresource_name, params
            
      unless model.toast_config.singles.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @single_finder = subresource_name
      @params = params
      @format = params[:format]
    end

    def get
      if @model.toast_config.in_collection.disallow_methods.include? "get"
        raise MethodNotAllowed 
      end
       
      record = if @model.toast_config.pass_params_to.include?(@single_finder) 
                  @model.send(@single_finder, @params)
                else
                  @model.send(@single_finder)
                end

      raise ResourceNotFound if record.nil?
      
      case @format
      when "html"
        {
          :template => "resources/#{model.to_s.underscore}",
          :locals => { model.to_s.pluralize.underscore.to_sym => record } 
        }
      when "json"        
        {
          :json => record.exposed_attributes,
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

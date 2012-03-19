module Toast
  class RootCollection < Resource
    
    attr_reader :model
    
    def initialize model, subresource_name, params
      
      subresource_name ||= "all"
      
      unless model.toast_config.collections.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @collection = subresource_name
      @params = params
      @format = params[:format]
    end

    def get
      if @model.toast_config.in_collection.disallow_methods.include? "get"
        raise MethodNotAllowed 
      end
       
      records = if @model.toast_config.pass_params_to.include?(@collection) 
                  @model.send(@collection, @params)
                else
                  @model.send(@collection)
                end

      case @format
      when "html"
        {
          :template => "resources/#{model.to_s.pluralize.underscore}",
          :locals => { model.to_s.pluralize.underscore.to_sym => records } 
        }
      when "json"        
        {
          :json => records.map{|r|
            r.exposed_attributes(:in_collection => true).
            merge( uri_fields(r, true) )
          },
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
      if @model.toast_config.in_collection.disallow_methods.include? "post"
        raise MethodNotAllowed
      end
        
      if @collection != "all"
        raise MethodNotAllowed
      end

      if self.media_type != @model.toast_config.media_type
        raise UnsupportedMediaType
      end

      begin 
        payload = ActiveSupport::JSON.decode(payload)
      rescue
        raise PayloadFormatError
      end
      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      # silently ignore all exposed readable, but not writable fields
      (@model.toast_config.readables - @model.toast_config.writables + ["uri"]).each do |rof|
        payload.delete(rof)
      end
      
      begin
        record = @model.create! payload              

        {
          :json => record.exposed_attributes.merge( uri_fields(record) ),
          :location => self.base_uri + record.uri_fullpath,
          :status => :created
        }
        
      rescue ActiveRecord::RecordInvalid => e
        # model validation failed
        raise PayloadInvalid.new(e.message)
      end
    end

    def delete
      raise MethodNotAllowed
    end
  end
end

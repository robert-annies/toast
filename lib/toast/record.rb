module Toast
  class Record < Resource

    attr_reader :model    
    
    def initialize model, id, format
      @model = model      
      @record = model.find(id) rescue raise(ResourceNotFound.new)
      @format = format
    end

    def post payload
      raise MethodNotAllowed
    end

    # get, put, delete, post return a Hash that can be used as
    # argument for ActionController#render

    def put payload       
      if self.media_type != @model.toast_config.media_type
        raise UnsupportedMediaType
      end

      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      if payload.keys.to_set != (@model.toast_config.exposed_attributes.to_set - @model.toast_config.auto_fields.to_set)
        raise PayloadInvalid
      end
      
      @record.update_attributes payload
      { 
        :json => @record.exposed_attributes,
        :status => :ok,
        :location => @record.uri
      }
    end

    def get
      case @format
      when "html", "xml"
        {
          :template => "resources/#{model.to_s.underscore}",
          :locals => { model.to_s.underscore.to_sym => @record } # full record, view should filter
        }
      when "json"
        {
          :json => @record.exposed_attributes,
          :status => :ok
        }
      else 
        raise ResourceNotFound
      end
    end

    def delete
      @record.destroy
      {
        :nothing => true,
        :status => :ok
      }
    end
  end
end

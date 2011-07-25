module Toast
  class RootCollection < Resource
    
    attr_reader :model
    
    def initialize model, subresource_name
      
      subresource_name ||= "all"
      
      unless model.toast_config.collections.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @collection = subresource_name
    end

    def get
      if @model.toast_config.in_collection.disallow_methods.include? "get"
        raise MethodNotAllowed 
      end

      records = @model.send(@collection)
      {
        :json => records.map{|r| r.exposed_attributes(:in_collection => true)},
        :status => :ok
      }
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

      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      if payload.keys.to_set != @model.toast_config.exposed_attributes.to_set
        raise PayloadInvalid
      end
      
      record = @model.create payload
      
      {
        :json => record.exposed_attributes,
        :location => record.uri,
        :status => :created
      }
    end

    def delete
      raise MethodNotAllowed
    end
  end
end

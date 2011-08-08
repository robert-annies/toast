module Toast
  class AssociateCollection < Resource
    
    attr_reader :model

    def initialize model, id, subresource_name
      unless model.toast_config.exposed_associations.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @record = model.find(id) rescue raise(ResourceNotFound)
      @collection = subresource_name

      @associate_model = Resource.get_class_by_resource_name subresource_name
      @associate_model.uri_base = @model.uri_base
      
    end

    def get
      records = @record.send(@collection)
      {
        :json => records.map{|r| r.exposed_attributes(:in_collection => true)},
        :status => :ok
      }
    end

    def put
      raise MethodNotAllowed
    end

    def post payload

      if self.media_type != @associate_model.toast_config.media_type
        raise UnsupportedMediaType
      end

      if payload.keys.to_set != (@associate_model.toast_config.exposed_attributes.to_set - @associate_model.toast_config.auto_fields.to_set)
        raise PayloadInvalid
      end

      unless payload.is_a? Hash
        raise PayloadFormatError
      end 

      record = @record.send(@collection).create payload
      
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

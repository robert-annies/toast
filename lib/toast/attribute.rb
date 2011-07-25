module Toast
  class Attribute < Resource

    attr_reader :model

    def initialize model, id, attribute_name
      unless model.toast_config.exposed_attributes.include? attribute_name
        raise ResourceNotFound 
      end

      @model = model
      @record = model.find(id) rescue raise(ResourceNotFound)
      @attribute_name = attribute_name
    end
    
    def get
      {
        :json => @record[@attribute_name],
        :status => :ok
      }
    end

    def put payload
      @record.update_attribute(@attribute_name, payload)
      { 
        :json => @record[@attribute_name],
        :stauts => :ok,
        :loaction => @record.uri
      }
    end

    def post payload
      raise MethodNotAllowed
    end
    
    def delete
      raise MethodNotAllowed
    end
  end
end

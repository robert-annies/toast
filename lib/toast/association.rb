module Toast
  class Association < Resource
    
    attr_reader :model

    def initialize model, id, subresource_name, format
      unless model.toast_config.exposed_associations.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @record = model.find(id) rescue raise(ResourceNotFound)
      @assoc = subresource_name
      @format = format
      @is_collection = [:has_many, :has_and_belongs_to_many].include? @model.reflect_on_association(@assoc.to_sym).macro

      @associate_model = Resource.get_class_by_resource_name subresource_name
      @associate_model.uri_base = @model.uri_base
      
    end

    def get
      result = @record.send(@assoc)

      if result.is_a? Array 
        {
          :json => result.map{|r| r.exposed_attributes(:in_collection => true)},
          :status => :ok
        }
      else
        {
          :json => result.exposed_attributes(:in_collection => true),
          :status => :ok
        }
      end

    end

    def put payload
      # only for has_one/belongs_to assocs            
      raise MethodNotAllowed if @is_collection

      
      begin 
        payload = ActiveSupport::JSON.decode(payload)
      rescue
        raise PayloadFormatError
      end


      unless payload.is_a? Hash
        raise PayloadFormatError
      end
      
      # update see record
      if self.media_type != @associate_model.toast_config.media_type
        raise UnsupportedMediaType
      end

      # silently ignore all exposed readable, but not writable fields
      (@associate_model.toast_config.readables - @associate_model.toast_config.writables).each do |rof|
        payload.delete(rof)
      end
      
      record = @record.send(@assoc)
      
      # set the virtual attributes 
      (payload.keys.to_set - record.attribute_names.to_set).each do |vattr|
        record.send("#{vattr}=", payload.delete(vattr))             
      end 
      
      # mass-update for the rest 
      record.update_attributes payload
      { 
        :json => record.exposed_attributes,
        :status => :ok,
        :location => record.uri
      }      
    end

    def post payload

      if self.media_type != @associate_model.toast_config.media_type
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
      (@associate_model.toast_config.readables - @associate_model.toast_config.writables).each do |rof|
        payload.delete(rof)
      end

      
      begin
        record = @record.send(@assoc).create! payload
      
        {
          :json => record.exposed_attributes,
          :location => record.uri,
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

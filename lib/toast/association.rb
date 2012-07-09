module Toast
  class Association < Resource

    attr_reader :model

    def initialize model, id, subresource_name, format, config, assoc_model, assoc_config_in, assoc_config_out
      
      unless config.exposed_associations.include? subresource_name
        raise ResourceNotFound
      end

      @model = model
      @record = model.find(id) rescue raise(ResourceNotFound)
      @assoc = subresource_name
      @format = format
      @is_collection = [:has_many, :has_and_belongs_to_many].include? @model.reflect_on_association(@assoc.to_sym).macro
      @config = config
      @associate_model = assoc_model
      @associate_config_in = assoc_config_in
      @associate_config_out = assoc_config_out

    end

    def get

      unless @record.class.reflect_on_all_associations.detect{|a| a.name.to_s == @assoc}
        raise "Toast Error: Association '#{@assoc}' not found in model '#{@record.class}'"
      end

      result = @record.send(@assoc)

      raise ResourceNotFound if result.nil?

      if result.is_a? Array
        {
          :json => result.map{|r|
            r.represent( @associate_config_out.in_collection.exposed_attributes,
                         @associate_config_out.in_collection.exposed_associations,
                         @base_uri,
                         @associate_config_out.media_type )
          },
          :status => :ok,
          :content_type => @associate_config_out.in_collection.media_type
        }
      else
        {
          :json =>  result.represent( @associate_config_out.exposed_attributes,
                                      @associate_config_out.exposed_associations,
                                      @base_uri,
                                      @associate_config_out.media_type),
          :status => :ok,
          :content_type => @associate_config_out.media_type
        }
      end

    end

    def put payload
      raise MethodNotAllowed
    end

    def post payload, media_type
      raise MethodNotAllowed unless @config.writables.include? @assoc

      if media_type != @associate_config_in.media_type
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
      (@associate_config_in.readables - @associate_config_in.writables).each do |rof|
        payload.delete(rof)
      end

      begin
        record = @record.send(@assoc).create! payload

        {
          :json => record.represent( @associate_config_out.exposed_attributes,
                                     @associate_config_out.exposed_associations,
                                     @base_uri,
                                     @associate_config_out.media_type),
          :location => self.base_uri + record.uri_path,
          :status => :created,
          :content_type => @associate_config_out.media_type
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

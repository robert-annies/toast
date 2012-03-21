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

      begin
        payload = ActiveSupport::JSON.decode(payload)
      rescue
        raise PayloadFormatError
      end

      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      # ignore all exposed readable, but not writable fields
      (@model.toast_config.readables - @model.toast_config.writables + ["uri"]).each do |rof|
        payload.delete(rof)
      end

      # set the virtual attributes
      (payload.keys.to_set - @record.attribute_names.to_set).each do |vattr|
        @record.send("#{vattr}=", payload.delete(vattr))
      end

      # mass-update for the rest
      @record.update_attributes payload
      {
        :json => @record.exposed_attributes.merge( uri_fields(@record) ),
        :status => :ok,
        :location => self.base_uri + @record.uri_fullpath
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
          :json => @record.exposed_attributes.merge( uri_fields(@record) ),
          :status => :ok
        }
      else
        raise ResourceNotFound
      end
    end

    def delete
      raise MethodNotAllowed unless @model.toast_config.deletable?

      @record.destroy
      {
        :nothing => true,
        :status => :ok
      }
    end

  end
end

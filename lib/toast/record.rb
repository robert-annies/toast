module Toast
  class Record < Resource

    attr_reader :model

    def initialize model, id, format, params, config_in, config_out
      @model = model
      @record = model.find(id) rescue raise(ResourceNotFound.new)
      @format = format
      @config_in = config_in
      @config_out = config_out
      @params = params
    end

    def post payload, media_type
      raise MethodNotAllowed
    end

    # get, put, delete, post return a Hash that can be used as
    # argument for ActionController#render

    def put payload, media_type

      if media_type != @config_in.media_type
        raise UnsupportedMediaType
      end

      begin
        payload = ActiveSupport::JSON.decode(payload).with_indifferent_access
      rescue
        raise PayloadFormatError
      end

      unless payload.is_a? Hash
        raise PayloadFormatError
      end

      # ignore all not explicitly writable attribute
      payload.delete_if {|key,value|
        !@config_in.writables.include?(key) or
        @config_in.exposed_associations.include?(key)
      }

      # set the virtual attributes
      (@config_in.writables - @record.attribute_names -  @config_in.exposed_associations).each do |vattr|

        unless (@record.respond_to?("#{vattr}=") && @record.method("#{vattr}=").arity == 1)
          raise "Toast Error: Connot find setter '#{@record.class}##{vattr}='"
        end
        # FIXME: omitted virtual attributes are set to nil, omiited non-virtual attributes are ignored
        @record.send("#{vattr}=", payload.delete(vattr))
      end

      # mass-update for the rest
      if @config_in.pass_params_to.include? 'self'
        # parameter passing
        @record.update_attributes! payload, @params
      else
        @record.update_attributes! payload
      end

      {
        :json => @record.represent( @config_out.exposed_attributes,
                                    @config_out.exposed_associations,
                                    @base_uri,
                                    @config_out.media_type ),
        :status => :ok,
        :location => self.base_uri + @record.uri_path,
        :content_type => @config_out.media_type
      }

    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotUnique => e
      # model validation failed
      raise PayloadInvalid.new(e.message)
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
          :json => @record.represent( @config_out.exposed_attributes,
                                      @config_out.exposed_associations,
                                      @base_uri,
                                      @config_out.media_type),
          :status => :ok,
          :content_type => @config_out.media_type
        }
      else
        raise ResourceNotFound
      end
    end

    def delete
      raise MethodNotAllowed unless @config_out.deletable?

      if @record.destroy
        {
          :nothing => true,
          :status => :no_content
        }
      else
        {
          :nothing => true,
          :status => :conflict
        }
      end

    end

    def link l
      raise MethodNotAllowed
    end

    def unlink l
      raise MethodNotAllowed
    end
  end
end

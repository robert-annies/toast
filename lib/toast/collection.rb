module Toast
  class Collection < Resource

    attr_reader :model

    def initialize model, subresource_name, params, config_in, config_out

      subresource_name ||= "all"

      unless config_out.collections.include? subresource_name
        if subresource_name == "all"
          ToastController.logger.debug "\n\tToast Debug: you may want to declare 'collections :all' in model '#{model}' to enable delivery of the collection '/#{model.to_s.underscore.pluralize}'\n"
        end
        raise ResourceNotFound
      end

      @model = model
      @collection = subresource_name
      @params = params
      @format = params[:format]
      @config_out = config_out
      @config_in = config_in
    end

    def get

      unless @model.respond_to?(@collection)
        raise "Toast Error: Cannot find class method '#{@collection}' of model '#{@model}', which is configured in 'acts_as_resource > collections'."
      end

      # FIXME: This is a lot of hallooballoo to check if the #send
      #        will be successful, but if it's not checked the error
      #        message is not helpful to find the error.

      if @config_out.pass_params_to.include?(@collection)
        if @model.method(@collection).arity**2 != 1
          raise "Toast Error: Class method '#{@collection}' of model '#{@model}' must accept one parameter, as configured by 'acts_as_resource > pass_params_to'."
        end

        # fetch results
        #binding.pry if $halt
        records, pagination_info = paginate_query( @config_out, @collection,
                                                   @model.send(@collection, @params),
                                                   @params )
      else

        if @model.method(@collection).arity > 0
          raise "Toast Error: Class method '#{@collection}' of model '#{@model}' must not accept any parameter, as configured by 'acts_as_resource'"
        end

        records, pagination_info = paginate_query( @config_out, @collection,
                                                   @model.send(@collection=='all'? 'scoped': @collection), # #scoped ?: #all would trigger query too early
                                                   @params )
      end

      case @format
      when "html"
        {
          :template => "resources/#{@model.to_s.pluralize.underscore}",
          :locals => { @model.to_s.pluralize.underscore.to_sym => records,
                       :pagination_info => pagination_info }
        }
      when "json"
        {
          :json => records.map{|r|
            r.represent( @config_out.in_collection.exposed_attributes,
                         @config_out.in_collection.exposed_associations,
                         self.base_uri,
                         @config_out.media_type)
          },
          :status => :ok,
          :content_type => @config_out.in_collection.media_type,
          :pagination_info => pagination_info
        }
      else
        raise ResourceNotFound
      end
    end

    def put
      raise MethodNotAllowed
    end

    def post payload, media_type
      raise MethodNotAllowed unless @config_in.postable?


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

      payload.delete_if {|key,value|
        !@config_in.writables.include?(key) or
        @config_in.exposed_associations.include?(key)
      }

      begin

        record = @model.create! payload

        {
          :json => record.represent( @config_out.exposed_attributes,
                                     @config_out.exposed_associations,
                                     self.base_uri,
                                     @config_out.media_type),
          :location => self.base_uri + record.uri_path,
          :status => :created,
          :content_type => @config_out.media_type
        }

      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotUnique => e
        # model validation failed
        raise PayloadInvalid.new(e.message)
      end
    end

    def delete
      raise MethodNotAllowed
    end

    def link l
      raise MethodNotAllowed
    end

    def unlink l
      raise MethodNotAllowed
    end

  end
end

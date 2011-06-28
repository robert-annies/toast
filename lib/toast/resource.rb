module Toast

  class ResourceNotFound < Exception; end
  class MethodNotAllowed < Exception; end
  class PayloadInvalid < Exception; end
  class PayloadFormatError < Exception; end
  class UnsupportedMediaType < Exception; end

  # Represents a resource. There are following resource types as sub classes:
  # Record, RootCollection, AssociateCollection, Attribute
  class Resource

    attr_accessor :media_type

    def initialize
      raise 'ToastResource#new: use #build to create an instance'
    end

    def self.build params, request

      resource_name = params[:resource]
      id = params[:id]
      subresource_name = params[:subresource]

      uri_base = "#{request.protocol}#{request.host}"
      unless (request.protocol == "http://" and request.port == 80) or
             (request.protocol == "https://" and request.port == 443)
        uri_base += ":#{request.port}"
      end

      begin

        model = get_class_by_resource_name resource_name

        model.uri_base = uri_base
        model.uri_base += "/#{model.toast_config.namespace}" if model.toast_config.namespace

        # decide which sub type
        rsc = if id.nil?
                Toast::RootCollection.new(model, subresource_name)
              elsif subresource_name.nil?
                Toast::Record.new(model, id)
              elsif model.toast_config.exposed_associations.include? subresource_name
                Toast::AssociateCollection.new(model, id, subresource_name)
              elsif model.toast_config.exposed_attributes.include? subresource_name
                Toast::Attribute.new(model, id, subresource_name)
              else
                raise ResourceNotFound
              end

        rsc.media_type = request.media_type

        rsc
      rescue NameError
        raise ResourceNotFound
      end
    end

    def self.get_class_by_resource_name name
      begin
        model = name.singularize.classify.constantize # raises NameError

        unless ((model.superclass == ActiveRecord::Base) and model.is_resourceful_model?)
          raise ResourceNotFound
        end

        model

      rescue NameError
        raise ResourceNotFound
      end
    end

    def apply method, payload
      case method
      when "PUT","POST"
        self.send(method.downcase, ActiveSupport::JSON.decode(payload))
      when "DELETE","GET"
        self.send(method.downcase)
      else
        raise MethodNotAllowed
      end
    end
  end
end


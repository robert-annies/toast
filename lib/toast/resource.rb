module Toast

  class ResourceNotFound < Exception; end
  class MethodNotAllowed < Exception; end
  class PayloadInvalid < Exception; end
  class PayloadFormatError < Exception; end
  class UnsupportedMediaType < Exception; end

  # Represents a resource. There are following resource types as sub classes:
  # Record, RootCollection, Association, Single
  class Resource

    attr_accessor :media_type

    def initialize
      raise 'ToastResource#new: use #build to create an instance'
    end

    def self.build params, request

      resource_name = params[:resource]
      id = params[:id]
      subresource_name = params[:subresource]
      format = params[:format]

      begin
        
        model = get_class_by_resource_name resource_name
                
        # base is complete URL until the resource name
        model.uri_base = request.url.match(/(.*)\/#{resource_name}(?:\..+|\/|\z)/)[1]

        # decide which sub type
        rsc = if id.nil? and model.toast_config.singles.include?(subresource_name)
                Toast::Single.new(model, subresource_name, params.clone)                 
              elsif id.nil?
                Toast::RootCollection.new(model, subresource_name, params.clone)
              elsif subresource_name.nil?
                Toast::Record.new(model, id, format)
              elsif model.toast_config.exposed_associations.include? subresource_name
                Toast::Association.new(model, id, subresource_name, format)                
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

      raise MethodNotAllowed if self.model.toast_config.disallow_methods.include?(method.downcase)
      
      case method
      when "PUT","POST"
        self.send(method.downcase, payload)
      when "DELETE","GET"
        self.send(method.downcase)
      else
        raise MethodNotAllowed
      end            
    end
  end
end


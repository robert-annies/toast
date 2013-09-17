module Toast

  class ResourceNotFound < Exception; end
  class MethodNotAllowed < Exception; end
  class PayloadInvalid < Exception; end
  class Conflict < Exception; end
  class PayloadFormatError < Exception; end
  class UnsupportedMediaType < Exception; end
  class RequestedVersionNotDefined < Exception; end
  class ResourceNotAcceptable < Exception; end

  # Represents a resource. There are following resource types as sub classes:
  # Record, Collection, Association, Single
  class Resource

    attr_accessor :prefered_media_type, :base_uri, :payload_content_type

    def initialize
      raise 'ToastResource#new: use #build to create an instance'
    end

    def self.build params, request
      resource_name = params[:resource]
      id = params[:id]
      subresource_name = params[:subresource]
      format = params[:format]

      begin

        # determine model
        model = get_class_by_resource_name resource_name

        # determine config for representation
        #  config_in: cosumed representation
        #  config_out: produced representation
        config_out = model.toast_config request.accept_media_types.prefered
        config_in = model.toast_config request.media_type

        #  ... or in case of an association request
        config_assoc_src = model.toast_config request.headers["Assoc-source-type"] # ?

        # base URI for returned object
        base_uri = request.base_url + request.script_name +
          (config_out.namespace ? "/" + config_out.namespace : "")

        # decide which sub resource type
        rsc = if id.nil? and config_out.singles.include?(subresource_name)
                Toast::Single.new(model, subresource_name, params.clone, config_in, config_out)
              elsif id.nil?
                Toast::Collection.new(model, subresource_name, params.clone, config_in, config_out)
              elsif subresource_name.nil?
                Toast::Record.new(model, id, format, params.clone, config_in, config_out)
              elsif (config_assoc_src && config_assoc_src.exposed_associations.include?(subresource_name))

                # determine associated model
                assoc_model =
                  model.reflect_on_all_associations.detect{|a| a.name.to_s == subresource_name}.klass

                # determine config for representation of assoc. model
                assoc_config_out = assoc_model.toast_config request.accept_media_types.prefered
                assoc_config_in = assoc_model.toast_config request.media_type

                # change base URI to associated record
                base_uri = request.base_url + request.script_name +
                  (assoc_config_out.namespace ? "/" + assoc_config_out.namespace : "")


                Toast::Association.new(model, id, subresource_name, params.clone, format, config_assoc_src,
                                       assoc_model, assoc_config_in, assoc_config_out)

              else
                raise ResourceNotFound
              end

        # set base to be prepended to URIs
        rsc.base_uri = base_uri



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

    def apply method, payload, payload_media_type, link_path_info
      case method
      when "PUT","POST"
        if link_path_info
          self.link link_path_info
        else
          self.send(method.downcase, payload, payload_media_type)
        end
      when "DELETE"
        if link_path_info
          self.unlink link_path_info
        else
          self.delete
        end
      when "GET"
        self.get
      else
        raise MethodNotAllowed
      end
    end

    private
    def uri_fields record, in_collection=false
      out = {}

      exposed_assoc =
        in_collection ? record.class.toast_config.in_collection.exposed_associations :
                        record.class.toast_config.exposed_associations

      exposed_assoc.each do |assoc|
        out[assoc] = "#{self.base_uri}#{record.uri_path}/#{assoc}"
      end

      out["self"] = self.base_uri + record.uri_path

      out
    end
  end
end

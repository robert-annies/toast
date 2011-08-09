require 'blockenspiel'
require 'toast/config_dsl'

module Toast
  module ActiveRecordExtensions

    # Configuration DSL
    def resourceful_model &block
      @toast_config = Toast::ConfigDSL::Base.new(self)
      Blockenspiel.invoke( block, @toast_config)

      # add class methods
      self.instance_eval do

        cattr_accessor :uri_base

        def is_resourceful_model?
          true
        end

        def toast_config
          @toast_config
        end
      end

      # add instance methods
      self.class_eval do
        # Return toast's standard uri for a record
        def uri
          "#{self.class.uri_base}/#{self.class.to_s.pluralize.underscore}/#{self.id}"
        end

        # Returns a Hash with all exposed attributes
        def exposed_attributes options = {}
          options.reverse_merge! :in_collection => false,
                                 :with_uri => true

          # attributes
          exposed_attr =
            options[:in_collection] ? self.class.toast_config.in_collection.exposed_attributes :
                                      self.class.toast_config.exposed_attributes

          out = exposed_attr.inject({}) do |acc, attr|
            acc[attr] = self.send attr
            acc
          end

          # association URIs
          exposed_assoc =
            options[:in_collection] ? self.class.toast_config.in_collection.exposed_associations :
                                      self.class.toast_config.exposed_associations

          exposed_assoc.each do |assoc|
            out[assoc] = self.uri + "/" + assoc
          end

          out["uri"] = self.uri if options[:with_uri]

          out
        end
      end
    end

    # defaults for non resourceful-models
    def is_resourceful_model?
      false
    end
    def resourceful_model_options
      nil
    end
    def resource_names
      @@all_resourceful_resource_names
    end
  end

end

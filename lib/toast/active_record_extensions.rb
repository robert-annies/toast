require 'blockenspiel'
require 'toast/config_dsl'

module Toast
  module ActiveRecordExtensions

    # Configuration DSL
    def acts_as_resource &block

      @toast_configs ||= Array.new
      @toast_configs << Toast::ConfigDSL::Base.new(self)

      Blockenspiel.invoke( block, @toast_configs.last)

      # add class methods
      self.instance_eval do

        def is_resourceful_model?
          true
        end

        def toast_configs
          @toast_configs
        end

        # get a config by media type or first one if none matches
        def toast_config media_type
          @toast_configs.find do |tc|
            tc.media_type == media_type || tc.in_collection.media_type == media_type
          end || @toast_configs.first
        end

        def toast_resource_uri_prefix
          @toast_resource_uri_prefix ||= self.to_s.pluralize.underscore
        end

      end

      # add instance methods
      self.class_eval do
        # Return the path segment of the URI of this record
        def uri_path
          "/" +
            self.class.toast_resource_uri_prefix + "/" +
            self.id.to_s
        end

        # Like ActiveRecord::Base.attributes, but result Hash includes
        # only attributes from the list _attr_names_ plus the
        # associations _assoc_names_ as links and the 'self' link
        def represent attr_names, assoc_names, base_uri, media_type
          props = {}

          attr_names.each do |name|
            unless self.respond_to?(name)
              raise "Toast Error: Connot find instance method '#{self.class}##{name}'"
            end
            props[name] = self.send(name)
          end

          assoc_names.each do |name|
            props[name] = "#{base_uri}#{self.uri_path}/#{name}"
          end

          props["self"] = base_uri + self.uri_path

          props
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
  end

  def self.resourceful_models
    Module.constants.select{ |c| (eval c).respond_to?(:toast_config)}.sort.map{|c| c.constantize}
  end

end

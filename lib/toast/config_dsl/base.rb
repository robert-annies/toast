require 'toast/config_dsl/expose'

class Toast::ConfigDSL::Base
  include Toast::ConfigDSL::Common

  def expose model_class, as: 'application/json', under: '', &block

    stack_push "expose(#{model_class})" do

      begin
        unless model_class.new.is_a?(ActiveRecord::Base)
          raise_config_error 'Directive requires an ActiveRecord::Base descendant.'
        end
      rescue ActiveRecord::StatementInvalid => error
        # may be raised when tables are not setup yet during database setup
        raise_config_error error.message
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      config_data = OpenStruct.new

      config_data.instance_eval do
        self.source_location = block.source_location.first

        self.model_class     = model_class
        self.media_type      = as
        self.url_path_prefix = under.split('/').delete_if(&:blank?)

        # defaults
        self.readables    = []
        self.writables    = []
        self.collections  = {}
        self.singles      = {}
        self.associations = {}
      end

      if Toast.expositions.detect{|exp| exp.model_class == config_data.model_class}
        raise_config_error "Model class #{exp.model_class} has already another configuration."
      end

      Toast.expositions << config_data

      # evaluate expose block
      Toast::ConfigDSL::Expose.new(config_data).instance_eval &block
    end
  end
end

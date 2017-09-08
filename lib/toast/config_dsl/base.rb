require 'toast/config_dsl/expose'

class Toast::ConfigDSL::Base
  include Toast::ConfigDSL::Common

  def expose model, as: 'application/json', under: '', &block

    stack_push "expose(#{model})" do

      unless model.new.is_a?(ActiveRecord::Base)
        raise_config_error 'Directive requires an ActiveRecord::Base descendant.'
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      config_data = OpenStruct.new

      config_data.instance_eval do
        # model
        self.model       = model
        self.media_type  = as
        self.url_path_prefix = under.split('/').delete_if(&:blank?)

        # defaults
        self.readables    = []
        self.writables    = []
        self.collections  = {}
        self.singles      = {}
        self.associations = {}
      end

      if Toast.expositions.detect{|exp| exp.model == config_data.model}
        raise_config_error "Model #{exp.model} has already another configuration."
      end

      Toast.expositions << config_data

      # evaluate expose block
      Toast::ConfigDSL::Expose.new(config_data).instance_eval &block
    end
  end
end

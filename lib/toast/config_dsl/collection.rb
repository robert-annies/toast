require 'toast/config_dsl/via_verb.rb'
require 'toast/config_dsl/default_handlers.rb'

class Toast::ConfigDSL::Collection
  include Toast::ConfigDSL::Common
  include Toast::ConfigDSL::DefaultHandlers

  def via_get &block
    stack_push 'via_get' do
      @config_data.via_get =
        OpenStruct.new(permissions: [],
                       handler: collection_get_handler(@config_data.base_model_class,
                                                       @config_data.collection_name))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_get).instance_eval &block

    end
  end

  def via_post &block
    stack_push 'via_post' do
      unless @config_data.collection_name == :all
        raise_config_error "POST is supported for the `all' collection only"
      end

      @config_data.via_post = OpenStruct.new(permissions: [],
                                             handler: collection_post_handler(@config_data.base_model_class))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_post).instance_eval &block

    end
  end

  def max_window size
    stack_push 'max_window' do
      if size.is_a?(Integer) and size > 0
        @config_data.max_window = size
      elsif size == :unlimited
        @config_data.max_window = 10**6 # yes that's inifinity 
      else
        raise_config_error 'max_window must a positive integer or :unlimited'
      end
    end
  end
end

class Toast::ConfigDSL::Single
  include Toast::ConfigDSL::Common
  include Toast::ConfigDSL::DefaultHandlers

  def via_get &block
    stack_push 'via_get' do

      @config_data.via_get =
        OpenStruct.new(permissions: [],
                       handler: single_get_handler(@config_data.model_class, @config_data.name))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_get).instance_eval &block
    end
  end
end

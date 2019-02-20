require 'toast/config_dsl/via_verb.rb'
require 'toast/config_dsl/default_handlers.rb'

class Toast::ConfigDSL::Association
  include Toast::ConfigDSL::Common
  include Toast::ConfigDSL::DefaultHandlers

  def via_get &block
    stack_push 'via_get' do
      @config_data.via_get =
        OpenStruct.new(permissions: [],
                       handler: (@config_data.singular ?
                                   singular_assoc_get_handler(@config_data.assoc_name) :
                                   plural_assoc_get_handler(@config_data.assoc_name)))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_get).instance_eval &block


    end
  end

  def via_post &block
    stack_push 'via_post' do
      if @config_data.singular
        raise_config_error "`via_post' is not allowed for singular associations"
      end

      @config_data.via_post = OpenStruct.new(permissions: [],
                                             handler: plural_assoc_post_handler(@config_data.assoc_name))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_post).instance_eval &block


    end
  end

  def via_link &block
    stack_push 'via_link' do
      @config_data.via_link = OpenStruct.new(permissions: [],
                                             handler: (@config_data.singular ?
                                                         singular_assoc_link_handler(@config_data.assoc_name) :
                                                         plural_assoc_link_handler(@config_data.assoc_name)))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_link).instance_eval &block

    end
  end

  def via_unlink &block
    stack_push 'via_unlink' do
      @config_data.via_unlink = OpenStruct.new(permissions: [],
                                               handler:  (@config_data.singular ?
                                                            singular_assoc_unlink_handler(@config_data.assoc_name) :
                                                            plural_assoc_unlink_handler(@config_data.assoc_name)))

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_unlink).instance_eval &block

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

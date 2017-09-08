require 'toast/config_dsl/association'
require 'toast/config_dsl/collection'
require 'toast/config_dsl/single'

# context for expose{} blocks
class Toast::ConfigDSL::Expose
  include Toast::ConfigDSL::Common
  include Toast::ConfigDSL::DefaultHandlers

  # directives
  def writables *attributes
    stack_push "writables(#{attributes.map(&:inspect).join(',')})" do

      check_symbol_list attributes

      model_class = @config_data.model_class

      attributes.each do |attr|

        model = model_class.new
        setter = (attr.to_s + '=').to_sym

        unless (model.respond_to?(setter) and model.method(setter).arity == 1)
          raise_config_error "Exposed attribute setter not found: `#{model_class.name}##{attr}='. Typo?"
        end

        unless (model.respond_to?(attr) and model.method(attr).arity.in?([-1,0]))
          raise_config_error "Exposed attribute getter not found `#{model_class.name}##{attr}'. Typo?"
        end

        @config_data.writables << attr
      end
    end
  end

  def readables *attributes
    stack_push "readables(#{attributes.map(&:inspect).join(',')})" do

      check_symbol_list attributes

      model_class = @config_data.model_class

      attributes.each do |attr|
        model = model_class.new

        unless (model.respond_to?(attr) and model.method(attr).arity.in?([-1,0]))
          raise_config_error "Exposed attribute getter not found `#{model_class.name}##{attr}'. Typo?"
        end

        @config_data.readables << attr
      end
    end
  end

  def via_get &block
    stack_push 'via_get' do
      @config_data.via_get =
        OpenStruct.new(permissions: [],
                       handler: canonical_get_handler)

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_get).instance_eval &block

    end
  end

  def via_patch &block
    stack_push 'via_patch' do
      @config_data.via_patch =
        OpenStruct.new(permissions: [],
                       handler: canonical_patch_handler)

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_patch).instance_eval &block

    end
  end

  def via_delete &block
    stack_push 'via_delete' do
      @config_data.via_delete =
        OpenStruct.new(permissions: [],
                       handler: canonical_delete_handler)

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_delete).instance_eval &block

    end
  end


  def collection name, as: 'application/json', &block
    stack_push "collection(#{name.inspect})" do
      model_class = @config_data.model_class

      unless block_given?
        raise_config_error 'Block expected.'
      end

      unless name.is_a?(Symbol)
        raise_config_error "collection name expected as Symbol"
      end

      unless model_class.respond_to?(name)
        raise_config_error "`#{name}' must be a callable class method."
      end

      @config_data.collections[name] =
        OpenStruct.new(base_model_class: model_class,
                       collection_name: name,
                       media_type: as,
                       max_window: Toast.settings.max_window)

      Toast::ConfigDSL::Collection.new(@config_data.collections[name]).
        instance_eval(&block)

    end
  end

  def single name, &block
    stack_push "single(#{name.inspect})" do

      model_class = @config_data.model_class

      unless model_class.respond_to?(name)
        raise_config_error "`#{name}' must be a callable class method."
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      @config_data.singles[name] = OpenStruct.new(name: name, model_class: model_class)

      Toast::ConfigDSL::Single.new(@config_data.singles[name]).
        instance_eval(&block)
    end
  end

  def association name, as: 'application/json', &block
    stack_push "association(#{name.inspect})" do


      model_class = @config_data.model_class

      unless name.is_a?(Symbol)
        raise_config_error "association name expected as Symbol"
      end

      unless model_class.reflections[name.to_s].
               try(:macro).in?([:has_many,
                                :has_one,
                                :belongs_to,
                                :has_and_belongs_to_many])
        raise_config_error 'Association expected'
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      target_model_class = model_class.reflections[name.to_s].klass
      macro    = model_class.reflections[name.to_s].macro
      singular = macro.in? [:belongs_to, :has_one]

      @config_data.associations[name] =
        OpenStruct.new(base_model_class: model_class,
                       target_model_class: target_model_class,
                       assoc_name: name,
                       media_type: as,
                       macro:      macro,
                       singular:   singular,
                       max_window: singular ? nil : Toast.settings.max_window)

      Toast::ConfigDSL::Association.new(@config_data.associations[name]).
        instance_eval(&block)
    end
  end
end

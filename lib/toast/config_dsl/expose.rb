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

      model = @config_data.model

      attributes.each do |attr|

        instance = model.new
        setter = (attr.to_s + '=').to_sym

        unless (instance.respond_to?(setter) and instance.method(setter).arity == 1)
          raise_config_error "Exposed attribute setter not found: `#{model.name}##{attr}='. Typo?"
        end

        unless (instance.respond_to?(attr) and instance.method(attr).arity == 0)
          raise_config_error "Exposed attribute getter not found `#{model.name}##{attr}'. Typo?"
        end

        @config_data.writables << attr
      end
    end
  end

  def readables *attributes
    stack_push "readables(#{attributes.map(&:inspect).join(',')})" do

      check_symbol_list attributes

      model = @config_data.model

      attributes.each do |attr|
        instance = model.new

        unless (instance.respond_to?(attr) and instance.method(attr).arity == 0)
          raise_config_error "Exposed attribute getter not found `#{model.name}##{attr}'. Typo?"
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

  def via_put &block
    stack_push 'via_put' do
      @config_data.via_put =
        OpenStruct.new(permissions: [],
                       handler: canonical_put_handler)

      Toast::ConfigDSL::ViaVerb.new(@config_data.via_put).instance_eval &block

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
      model = @config_data.model

      unless block_given?
        raise_config_error 'Block expected.'
      end

      unless name.is_a?(Symbol)
        raise_config_error "collection name expected as Symbol"
      end

      unless model.respond_to?(name)
        raise_config_error "`#{name}' must be a callable class method."
      end

      @config_data.collections[name] =
        OpenStruct.new(base_model: model,
                       collection_name: name,
                       media_type: as,
                       max_window: Toast.globals[:max_window])

      Toast::ConfigDSL::Collection.new(@config_data.collections[name]).
        instance_eval(&block)

    end
  end

  def single name, &block
    stack_push "single(#{name.inspect})" do

      model = @config_data.model

      unless model.respond_to?(name)
        raise_config_error "`#{name}' must be a callable class method."
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      @config_data.singles[name] = OpenStruct.new(name: name, model: model)

      Toast::ConfigDSL::Single.new(@config_data.singles[name]).
        instance_eval(&block)
    end
  end

  def association name, as: 'application/json', &block
    stack_push "association(#{name.inspect})" do


      model = @config_data.model

      unless name.is_a?(Symbol)
        raise_config_error "association name expected as Symbol"
      end

      unless model.reflections[name.to_s].is_a?(ActiveRecord::Reflection::AssociationReflection)
        raise_config_error 'Model association expected'
      end

      unless block_given?
        raise_config_error 'Block expected.'
      end

      target_model = model.reflections[name.to_s].klass
      macro    = model.reflections[name.to_s].macro
      singular = macro.in? [:belongs_to, :has_one]

      @config_data.associations[name] =
        OpenStruct.new(base_model: model,
                       target_model: target_model,
                       assoc_name: name,
                       media_type: as,
                       macro:      macro,
                       singular:   singular,
                       max_window: singular ? nil : Toast.globals[:max_window])

      Toast::ConfigDSL::Association.new(@config_data.associations[name]).
        instance_eval(&block)
    end
  end
end

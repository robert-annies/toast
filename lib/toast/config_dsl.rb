module Toast
  module ConfigDSL

    class Base
      include Blockenspiel::DSL
      dsl_attr_accessor :media_type, :has_many, :namespace

      def initialize model
        @model = model
        @fields = []
        @collections = []
        @media_type = "application/json"
        @exposed_attributes = []
        @exposed_associations = []
        @in_collection = ConfigDSL::InCollection.new model, self
      end

      def fields= *fields
        @fields.push *ConfigDSL.sanitize(fields,"fields")
        @fields.each do |attr_or_assoc|
          if @model.new.attributes.keys.include? attr_or_assoc
            @exposed_attributes << attr_or_assoc
          else
            @exposed_associations << attr_or_assoc
          end
        end

      end

      def fields *arg
        return(@fields) if arg.empty?
        self.fields = *arg
      end

      attr_reader :exposed_attributes, :exposed_associations

      def collections= collections=[]
        @collections = ConfigDSL.sanitize(collections, "collections")
      end

      def collections *arg
        return(@collections) if arg.empty?
        self.collections = *arg
      end

      def in_collection &block
        if block_given?
          Blockenspiel.invoke( block, @in_collection)
        else
          @in_collection
        end
      end

      # non DSL methods
      dsl_methods false
    end

    class InCollection
      include Blockenspiel::DSL

      def initialize model, base_config
        @model = model
        @fields = base_config.fields
        @exposed_attributes = base_config.exposed_attributes
        @exposed_associations = base_config.exposed_associations
        @media_type = "application/json"
      end

      def fields= *fields
        @fields = ConfigDSL.sanitize(fields,"fields")

        @exposed_attributes = []
        @exposed_associations = []

        @fields.each do |attr_or_assoc|
          if @model.new.attributes.keys.include? attr_or_assoc
            @exposed_attributes << attr_or_assoc
          else
            @exposed_associations << attr_or_assoc
          end
        end
      end

      def fields *arg
        return(@fields) if arg.empty?
        self.fields = *arg
      end

      attr_reader :exposed_attributes, :exposed_associations
    end


    # Helper

    # checks if list is made of symbols and strings
    # converts a single value to an Array
    # converts all symbols to strings
    def self.sanitize list, name
      list = [list].flatten

      list.map do |x|
        if (!x.is_a?(Symbol) && !x.is_a?(String))
          raise "Toast Config Error: '#{name}' should be a list of Symbols or Strings"
        else
          x.to_s
        end
      end
    end


  end
end

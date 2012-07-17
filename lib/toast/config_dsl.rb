module Toast
  module ConfigDSL

    class Base
      include Blockenspiel::DSL
      dsl_attr_accessor :namespace, :media_type

      def initialize model
        @model = model
        @readables = []
        @writables = []
        @collections = []
        @singles = []
        @deletable = false
        @postable = false
        @pass_params_to = []
        @before_scoped_create = {}
        @in_collection = ConfigDSL::InCollection.new model, self
        @media_type = "application/json"

        @model.attr_accessible []
      end

      def exposed_attributes
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@writables + @readables).uniq.select{|f| !assocs.include?(f)}
      end

      def exposed_associations
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@writables + @readables).uniq.select{|f| assocs.include?(f)}
      end

      def readables= arg
          @readables.push *ConfigDSL.sanitize(arg,"readables")
      end

      # args: Array or :all, :except => Array
      def readables *arg
        return(@readables) if arg.empty?
        self.readables = arg
      end

      def writables= arg
        @model.attr_accessible *arg
        @writables.push *ConfigDSL.sanitize(arg,"writables")
      end

      # args: Array or :all, :except => Array
      def writables *arg
        return(@writables) if arg.empty?
        self.writables = arg
      end

      def deletable
        @deletable = true
      end

      def deletable?
        @deletable
      end

      def postable
        @postable = true
      end

      def postable?
        @postable
      end

      def pass_params_to= arg
        @pass_params_to.push *ConfigDSL.sanitize(arg,"pass_params_to")
      end

      def pass_params_to *arg
        return(@pass_params_to) if arg.empty?
        self.pass_params_to = arg
      end

      def before_scoped_create= arg
        for key in arg.keys
          @before_scoped_create[key.to_s] = arg[key].to_sym
        end
      end

      def before_scoped_create arg={}
        return(@before_scoped_create) if arg.empty?
        self.before_scoped_create = arg
      end

      def collections= collections=[]
        @collections = ConfigDSL.sanitize(collections, "collections")
      end

      def collections *arg
        return(@collections) if arg.empty?
        self.collections = arg
      end

      def singles= singles=[]
        @singles = ConfigDSL.sanitize(singles, "singles")
      end

      def singles *arg
        return(@singles) if arg.empty?
        self.singles = arg
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

      dsl_attr_accessor :media_type

      def initialize model, base_config
        @model = model
        @media_type = "application/json"
        @readables = base_config.readables # must assign a reference
        @writables = base_config.writables # must assign a reference
      end

      def readables= readables
        @writables = [] # forget inherited writables
        @readables = ConfigDSL.sanitize(readables,"readables")
      end

      def readables *arg
        return(@readables) if arg.empty?
        self.readables = arg
      end

      def writables *arg
        self.writables = 42
      end
      
      def writables= arg
        puts
        puts "Toast Config Warning (#{model.class}): Defining \"writables\" in collection definition has no effect."
        puts
      end

      def namespace *arg
        self.writables = 42
      end

      def namespace= arg
        puts
        puts "Toast Config Warning (#{model.class}): Defining \"namespace\" in collection definition has no effect."
        puts
      end

      def exposed_attributes
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@readables + @writables).uniq.select{|f| !assocs.include?(f)}
      end

      def exposed_associations
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@readables + @writables).uniq.select{|f| assocs.include?(f)}
      end

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

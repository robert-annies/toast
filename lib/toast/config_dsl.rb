module Toast
  module ConfigDSL

    class Base
      include Blockenspiel::DSL
      dsl_attr_accessor :media_type, :has_many, :namespace

      def initialize model
        @model = model
        @readables = ["uri"]
        @writables = []
        @collections = []
        @singles = []
        @media_type = "application/json"
        @disallow_methods = []
        @pass_params_to = []
        @in_collection = ConfigDSL::InCollection.new model, self
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
        #if arg.first == :all
        #  @readables.push @model.attribute_names - ConfigDSL.sanitize(args.last[:except], "readables")
        #else
          @readables.push *ConfigDSL.sanitize(arg,"readables")          
        #end
      end

      # args: Array or :all, :except => Array
      def readables *arg
        return(@readables) if arg.empty?
        self.readables = arg        
      end

      def writables= arg
        #if arg.first == :all
        #  @writables.push @model.attribute_names - ConfigDSL.sanitize(args.last[:except], "writables")
        #else
        # white list writables (protect the rest from mass-assignment)
        @model.attr_accessible *arg
        @writables.push *ConfigDSL.sanitize(arg,"writables")          
        #end
      end

      # args: Array or :all, :except => Array
      def writables *arg
        return(@writables) if arg.empty?
        self.writables = arg        
      end

     
      def disallow_methods= arg
        @disallow_methods.push *ConfigDSL.sanitize(arg,"disallow methods")
      end

      def disallow_methods *arg
        return(@disallow_methods) if arg.empty?
        self.disallow_methods = arg        
      end

      def pass_params_to= arg
        @pass_params_to.push *ConfigDSL.sanitize(arg,"pass_params_to")
      end

      def pass_params_to *arg
        return(@pass_params_to) if arg.empty?
        self.pass_params_to = arg        
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

      def initialize model, base_config
        @model = model
        @readables = base_config.readables # must assign a reference 
        @writables = base_config.writables # must assign a reference 
        @disallow_methods = []
        @media_type = "application/json"
      end

      def readables= readables
        @writables = [] # forget inherited writables
        @readables = ConfigDSL.sanitize(readables,"readables") << "uri"
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

      def exposed_attributes
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@readables + @writables).uniq.select{|f| !assocs.include?(f)}
      end

      def exposed_associations
        assocs = @model.reflect_on_all_associations.map{|a| a.name.to_s}
        (@readables + @writables).uniq.select{|f| assocs.include?(f)}
      end

      def disallow_methods= arg
        @disallow_methods.push *ConfigDSL.sanitize(arg,"disallow methods")
      end

      def disallow_methods *arg
        return(@disallow_methods) if arg.empty?
        self.disallow_methods = arg        
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

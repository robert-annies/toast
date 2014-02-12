module Toast
  module ConfigDSL

    class Base
      include Blockenspiel::DSL
      dsl_attr_accessor :namespace, :media_type

      def initialize model
        @model = model
        @readables = []
        @writables = []
        @field_comments = {}
        @collections = []
        @singles = []
        @deletable = false
        @postable = false
        @pass_params_to = []
        @in_collection = ConfigDSL::InCollection.new model, self
        @media_type = "application/json"
        @apidoc = {}

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
        @field_comments.merge! ConfigDSL.get_comments(arg, 'ro')
        @readables.push *ConfigDSL.normalize(arg,"readables")
      end

      # args: Array or :all, :except => Array
      def readables *arg
        return(@readables) if arg.empty?
        self.readables = arg
      end

      def writables= arg
        @model.attr_accessible *arg
        @field_comments.merge! ConfigDSL.get_comments(arg, 'rw')
        @writables.push *ConfigDSL.normalize(arg,"writables")
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
        @pass_params_to.push *ConfigDSL.normalize(arg,"pass_params_to")
      end

      def pass_params_to *arg
        return(@pass_params_to) if arg.empty?
        self.pass_params_to = arg
      end

      def collections= collections=[]
        @collections = ConfigDSL.normalize(collections, "collections")
      end

      def collections *arg
        return(@collections) if arg.empty?
        self.collections = arg
      end

      def singles= singles=[]
        @singles = ConfigDSL.normalize(singles, "singles")
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

      def apidoc arg=nil
        return(@apidoc) if arg.nil?
        raise "Toast Config Error (#{model.class}): apidoc argument must be a Hash." unless arg.is_a?(Hash)
        @apidoc = arg
      end

      # non DSL methods
      dsl_methods false

      def field_comments
        @field_comments
      end
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
        @readables = ConfigDSL.normalize(readables,"readables")
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

    end # class InCollection

    # Helper

    # checks if list is made of symbols and strings
    # converts a single value to an Array
    # converts all symbols to strings
    def self.normalize list, name
      # make single element list
      list = [list] unless list.is_a? Array

      # remove all comments
      list = list.map{|x| x.is_a?(Array) ? x.first : x}

      # flatten
      list = [list].flatten

      # check class and stringify
      list.map do |x|
        if (!x.is_a?(Symbol) && !x.is_a?(String))
          raise "Toast Config Error: '#{name}' should be a list of Symbols"
        else
          x.to_s
        end
      end
    end

    # fields (readables and writables) can have comments , if passed by Arrays of the form:
    # [symbol, comment]
    # returns a Hash of all commented or uncommented fields as:
    # { FIELD_NAME => {:comment => COMMENT, :type => type } }
    def self.get_comments arg, access
      comments = {}

      if arg.is_a? Array
        arg.each do |f|
          if f.is_a? Array
            comments[ f.first.to_s ] = {:comment => f[1].to_s, :access => access, :type => f[2]}
          else
            comments[ f.to_s ] = {:comment => '[ no comment ]', :access => access, :type => nil}
          end
        end
      end

      comments
    end
  end
end

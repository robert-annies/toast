require "rake/testtask"

begin
  require "jeweler"

  # monkey patch: gem install -Vl 
  # otherwise it tries to download specs form rubygems.org everytime   
  class Jeweler::Commands::InstallGem
      def run	
        command = "#{gem_command} install -Vl #{gemspec_helper.gem_path}"
        output.puts "Executing #{command.inspect}:"

        sh command # TODO where does sh actually come from!? - rake, apparently
      end
  end


  Jeweler::Tasks.new do |gem|
    gem.name = "toast"
    gem.summary = "Toast adds a RESTful interface to ActiveRecord models in Ruby on Rails."
    gem.author = "Robert Annies"
    gem.description = "Toast is an extension to Ruby on Rails that lets you expose any
ActiveRecord model as a resource according to the REST paradigm. The
representation format is JSON."
    gem.email = "robokopp@fernwerk.net"
    gem.homepage = "https://github.com/robokopp/toast"
    gem.files = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*"]

    gem.add_dependency 'blockenspiel', '~> 0.4.2'
    gem.add_dependency 'rack-accept-media-types', '~> 0.9'	
    
  end
rescue LoadError
  puts "Please install jeweler first"
  exit -1
end

desc 'Run toast test suite'
Rake::TestTask.new(:test => :install) do |t|
  t.libs << 'test/rails_app/lib'
  t.libs << 'test/rails_app/test'
  t.libs << 'test/rails_app/test/app/models'
  t.libs << 'test/rails_app/test/app/controllers'
  t.pattern = 'test/rails_app/test/**/*_test.rb'
  t.verbose = true
end


require "rake/testtask"

begin
  require "jeweler"
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
  end
rescue LoadError
  puts "Please install jeweler to run the test suite"
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


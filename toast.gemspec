# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require "toast/version"

Gem::Specification.new do |s|
  s.name = "toast"
  s.version = Toast::VERSION
  s.description = "Toast is an extension to Ruby on Rails that lets you expose any
ActiveRecord model as a resource according to the REST paradigm via a generic controller. The default
representation format is JSON or can be anything"  
  s.summary = "Toast adds a RESTful interface to ActiveRecord models in Ruby on Rails."
  s.authors = ["robokopp (Robert Anniés)"]
  s.email = "robokopp@fernwerk.net"
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
             "app/controller/toast_controller.rb",
             "config/routes.rb",
             "lib/toast.rb",
             "lib/toast/version.rb",
             "lib/toast/active_record_extensions.rb",
             "lib/toast/association.rb",
             "lib/toast/collection.rb",
             "lib/toast/config_dsl.rb",
             "lib/toast/engine.rb",
             "lib/toast/record.rb",
             "lib/toast/resource.rb",
             "lib/toast/single.rb",
             "lib/toast/scoped_associations.rb"]
  s.homepage = "https://github.com/robokopp/toast"
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.add_development_dependency('shoulda')
  s.add_dependency('blockenspiel','~> 0.4.2')
  s.add_dependency('rack-accept-media-types','~> 0.4.2')  
end

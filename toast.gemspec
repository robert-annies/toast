$:.unshift File.expand_path("../lib", __FILE__)
require "toast/version"

Gem::Specification.new do |s|
  s.name = "toast"
  s.version = Toast::VERSION
  s.description = "Toast is an extension to Ruby on Rails 3 and 4 that lets you expose any ActiveRecord model as a web resource. Operations follow the REST/Hypermedia API principles implemented by a generic hidden controller."
  s.summary = "Toast adds a Hypermedia API to ActiveRecord models in Ruby on Rails."
  s.authors = ["robokopp (Robert Annies)"]
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
             "lib/toast/single.rb"
             ]
  s.homepage = "https://github.com/robokopp/toast"
  s.require_paths = ["lib"]
  s.add_dependency('rails','>= 3.1.0')
  s.add_dependency('blockenspiel','~> 0.4.2')
  s.add_dependency('rack-accept-media-types','~> 0.9')
  s.add_dependency('rack-link_headers', '~> 2.2.2')
end

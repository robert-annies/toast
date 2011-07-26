# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{toast}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robert Annies"]
  s.date = %q{2011-07-26}
  s.description = %q{Toast is an extension to Ruby on Rails that lets you expose any
ActiveRecord model as a resource according to the REST paradigm. The
representation format is JSON.}
  s.email = %q{robokopp@fernwerk.net}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "app/controller/toast_controller.rb",
    "config/routes.rb",
    "lib/toast.rb",
    "lib/toast/active_record_extensions.rb",
    "lib/toast/associate_collection.rb",
    "lib/toast/attribute.rb",
    "lib/toast/config_dsl.rb",
    "lib/toast/engine.rb",
    "lib/toast/record.rb",
    "lib/toast/resource.rb",
    "lib/toast/root_collection.rb"
  ]
  s.homepage = %q{https://github.com/robokopp/toast}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Toast adds a RESTful interface to ActiveRecord models in Ruby on Rails.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<blockenspiel>, ["~> 0.4.2"])
    else
      s.add_dependency(%q<blockenspiel>, ["~> 0.4.2"])
    end
  else
    s.add_dependency(%q<blockenspiel>, ["~> 0.4.2"])
  end
end


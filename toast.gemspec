$:.unshift File.expand_path("../lib", __FILE__)
require "toast/version"

Gem::Specification.new do |s|
  s.name = "toast"
  s.version = Toast::VERSION
  s.description = <<EOF
Toast is a Rack application that hooks into Ruby on Rails. It exposes ActiveRecord models as 
a web service (REST API). The main difference from doing that with Ruby on Rails itself is 
it's DSL that covers all aspects of an API in one single configuration.
EOF
  s.summary = "Toast exposes ActiveRecord models as a web service (REST API)."
  s.authors = ["robokopp (Robert Annies)"]
  s.email = "robokopp@fernwerk.net"
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = ['config/routes.rb',
             'lib/toast.rb'] +
             Dir['lib/toast/**/*.rb'] +
             Dir['lib/generators/**/*.{rb,erb}'] + 
            ['lib/generators/toast/USAGE']
             
  s.homepage = "https://github.com/robokopp/toast"
  s.require_paths = ["lib"]
  s.add_dependency('rails','~> 5')
  s.add_dependency('rack-accept-media-types','~> 0.9')
  s.add_dependency('link_header', '~> 0.0.8')
end

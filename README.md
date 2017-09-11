[![Gem Version](https://badge.fury.io/rb/toast.png)](http://badge.fury.io/rb/toast)

Summary
=======

Toast is a Rack application that hooks into Ruby on Rails. It exposes ActiveRecord models as a web service (REST API). The main difference from doing that with Ruby on Rails itself is it's DSL that covers all aspects of an API in one single configuration. For each model and API endpoint you define:

  * what models and attributes are to be exposed
  * what methods are supported  (GET, PATCH, DELETE, POST,...)
  * hooks to handle authorization
  * customized handlers 

When using Toast there's no Rails controller involved. Model classes and the API configuration is sufficient. 

Toast uses a REST/hypermedia style API, which is an own interpretation of the REST idea, not compatible with others like JSON API, Siren etc. It's design is much simpler and based on the idea of traversing opaque URIs. 

Other features are:

  * windowing of collections via _Range/Content-Range_ headers (paging)
  * attribute selection per request 
  * processing of URI parameters

Toast v1 is build for Rails 5. The predecesssor v0.9 supports 3 and 4, but has a much different and smaller DSL.

See the [User Manual](https://robokopp.github.io/toast) for a detailed description.

Status
======

Toast v1 for Rails 5 is a complete rewrite of v0.9, which was first published and used in production since 2012. 
It comes now with secure defaults: Nothing is exposed unless declared, all endpoints have a default authorization hook responding with 401. 

v1 is not compatible with v0.9, and it is not tested with Rails < v5. All configurations must be ported to the new DSL. 

From my point of view it is production ready. I am in the process of porting a large API from v0.9 to v1 that uses all features and it looks very good so far. Of course minor issues will appear, please help to report and fix them. 

Installation
============

with Bundler (Gemfile) from Rubygems:

    source 'http://rubygems.org'
    gem "toast"

from Github:

    gem "toast", :git => "https://github.com/robokopp/toast.git"

then run

    bundle
    rails generate toast init
      create  config/toast-api.rb
      create  config/toast-api

Example
=======

Let the table _bananas_ have the following schema:

     create_table "bananas", :force => true do |t|
       t.string   "name"
       t.integer  "number"
       t.string   "color"
       t.integer  "apple_id"
     end

and let a corresponding model class have this code:

     class Banana < ActiveRecord::Base
       belongs_to :apple
       has_many :coconuts

       scope :less_than_100, -> { where("number < 100") }
     end

Then we can define the API like this (in `config/toast-api/banana.rb`):

      expose(Banana) {

         readables :color
         writables :name, :number

         via_get {
            allow do |user, model, uri_params|
              true
            end
         }

         via_patch {
            allow do |user, model, uri_params|
              true
            end          
         }

         via_delete {
            allow do |user, model, uri_params|
              true
            end          
         }

         collection(:less_than_100) {
           via_get {
             allow do |user, model, uri_params|
               true
             end
           }
         }

         collection(:all) {
           max_window 16

           via_get {
             allow do |user, model, uri_params|
               true
             end
           }

           via_post {
             allow do |user, model, uri_params|
               true
             end
           }
         }

         association(:coconuts) {
           via_get {
             allow do |user, model, uri_params|
               true
             end

             handler do |banana, uri_params|
               if uri_params[:max_weight] =~ /\A\d+\z/
                 banana.coconuts.where("weight <= #{uri_params[:max_weight]}")
               else
                 banana.coconuts
               end.order(:weight)
             end
           }

           via_post {
             allow do |user, model, uri_params|
               true
             end
           }          

           via_link {
             allow do |user, model, uri_params|
               true
             end
           }          
         }

         association(:apple) {
           via_get {
             allow do |user, model, uri_params|
               true
             end
           }          
         }
      }

Note, that all allow-blocks in the above example return _true_. In practice authorization logic should be applied. An allow-block must be defined for each endpoint because it defaults to return _false_, which causes a _401 Unauthorized_ response.

The above definition exposes the model Banana as such:

### Get a single resource representation:
    GET http://www.example.com/bananas/23
    --> 200,  '{"self":     "http://www.example.com/bananas/23"
                "name":     "Fred",
                "number":   33,
                "color":    "yellow",
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple":    "http://www.example.com/bananas/23/apple" }'

The representation of a record is a flat JSON map: _name_ → _value_, in case of associations _name_ → _URI_. The special key _self_ contains the URI from which this record can be fetch alone. _self_ can be treated as a  unique ID of the record (globally unique, if under a FQDN). 

### Get a collection (the :all collection)
    GET http://www.example.com/bananas
    --> 200,  '[{"self":     "http://www.example.com/bananas/23",
                 "name":     "Fred",
                 "number":   33,
                 "color":    "yellow",
                 "coconuts": "http://www.example.com/bananas/23/coconuts",
                 "apple":    "http://www.example.com/bananas/23/apple,
                {"self":     "http://www.example.com/bananas/24",
                  ... }, ... ]'

The default length of collections is limited to 42, this can be adjusted globally or for each endpoint separately. In this case no more than 16 will be delivered due to the `max_window 16` directive.

### Get a customized collection
    GET http://www.example.com/bananas/less_than_100
    --> 200, '[{BANANA}, {BANANA}, ...]'

Any _scope_ or class method returning a relation can be published this way.

### Get an associated collection + filter
    GET http://www.example.com/bananas/23/coconuts?max_weight=3
    --> 200, '[{COCONUT},{COCONUT},...]',

 The COCONUT model must be exposed too. URI parameters can be processed in custom handlers for sorting and filtering. 

### Update a single resource:
    PATCH http://www.example.com/bananas/23, '{"name": "Barney", "number": 44, "foo" => "bar"}'
    --> 200,  '{"self":     "http://www.example.com/bananas/23"
                "name":     "Barney",
                "number":   44,
                "color":    "yellow",
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple":    "http://www.example.com/bananas/23/apple"}'

Toast ingores unknown attributes, but prints warnings in it's log file. Only attributes from the 'writables' list will be updated. 

### Create a new record
    POST http://www.example.com/bananas, '{"name": "Johnny", "number": 888}'
    --> 201, '{"self":     "http://www.example.com/bananas/102"
               "name":     "Johnny",
               "number":    888,
               "color":     null,
               "coconuts": "http://www.example.com/bananas/102/coconuts",
               "apple":    "http://www.example.com/bananas/102/apple }'

### Create an associated record
    POST http://www.example.com/bananas/23/coconuts, '{COCONUT}'
    --> 201,  {"self":"http://www.example.com/coconuts/432, ...}

  
### Delete records
    DELETE http://www.example.com/bananas/23
    --> 200

### Linking records

    LINK "http://www.example.com/bananas/23/coconuts", 
      Link:  "http://www.example.com/coconuts/31"
    --> 200

Toast uses the (unusual) HTTP verbs LINK and UNLINK in order to express the action of linking or unlinking existing resources. The above request will add _Coconut#31_ to the association _Banana#coconuts_. 




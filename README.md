[![Gem Version](https://badge.fury.io/rb/toast.png)](http://badge.fury.io/rb/toast)

Summary
=======

Toast is an extension to Ruby on Rails to build web services with low
programming effort in a coherent way.  Toast extends ActiveRecord such
that each model can be declared to be a web resource, exposing defined
attributes for reading and writing using HTTP.

Its main features are:

  * declaration of web resources based on ActiveRecord models
  * generic controller handles all actions
  * automated routing
  * exposing data values with JSON maps
  * exposing associations by links (URLs)

Toast works with

  * Ruby on Rails >= 3.1.0 (currently tested up to 3.2.16)
  * Ruby 1.8.7, 1.9.3, 2.0.0

See the [User Manual](https://github.com/robokopp/toast/wiki/User-Manual) for a detailed description.

WARNING
=======

This version is experimental and probably not bullet
proof. As soon as the gem is loaded a controller with ready routing is
enabled serving the annotated model's data records.

Version 1.0.0 of Toast is planned to be a production-ready implementation,
which will be finished within 2012. Until then API/DSL changes must
be expected with each minor update.

Example
=======

Let the table `bananas` have the following schema:

     create_table "bananas", :force => true do |t|
       t.string   "name"
       t.integer  "number"
       t.string   "color"
       t.integer  "apple_id"
     end

and let a corresponding model class have a *acts_as_resource* annotation:

     class Banana < ActiveRecord::Base
       belongs_to :apple
       has_many :coconuts

       scope :less_than_100, where("number < 100")

       acts_as_resource do
         # exposed attributes or association names
         readables :coconuts, :apple
         writables :name, :number

         # exposed class methods of Banana returning an Array of Banana records
         collections :less_than_100, :all
       end
     end

The above definition inside the `acts_as_resource` block exposes the
records of the model Banana automatically via a generic controller to
the outside world, accepting and delivering JSON representations of
the records. Let the associated models Apple and Coconut be
exposed as a resource, too:

### Get a collection
    GET /bananas
    --> 200,  '[{"self":     "http://www.example.com/bananas/23",
                 "name":     "Fred",
                 "number":   33,
                 "coconuts": "http://www.example.com/bananas/23/coconuts",
                 "apple":    "http://www.example.com/bananas/23/apple,
                {"self":     "http://www.example.com/bananas/24",
                  ... }, ... ]
### Get a customized collection (filtered, paging, etc.)
    GET /bananas/less_than_100
    --> 200, '[{BANANA}, {BANANA}, ...]'

### Get a single resource representation:
    GET /bananas/23
    --> 200,  '{"self":     "http://www.example.com/bananas/23"
                "name":     "Fred",
                "number":   33,
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple":    "http://www.example.com/bananas/23/apple" }'

### Get an associated collection
    "GET" /bananas/23/coconuts
    --> 200, '[{COCNUT},{COCONUT},...]',

### Update a single resource:
    PUT /bananas/23, '{"self":   "http://www.example.com/bananas/23"
                       "name":   "Barney",
                       "number": 44}'
    --> 200,  '{"self":     "http://www.example.com/bananas/23"
                "name":     "Barney",
                "number":   44,
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple":    "http://www.example.com/bananas/23/apple"}'

### Create a new record
    "POST" /bananas,  '{"name": "Johnny",
                        "number": 888}'
    --> 201,  {"self":     "http://www.example.com/bananas/102"
               "name":     "Johnny",
               "number":   888,
               "coconuts": "http://www.example.com/bananas/102/coconuts" ,
               "apple":    "http://www.example.com/bananas/102/apple }

### Create an associated record
    "POST" /bananas/23/coconuts, '{COCONUT}'
    --> 201,  {"self":"http://www.example.com/coconuts/432,
               ...}

### Delete records
    DELETE /bananas/23
    --> 200

More details and configuration options are documented in the manual.

Installation
============

With bundler from  (rubygems.org)

    gem "toast"

the latest Git:

    gem "toast", :git => "https://github.com/robokopp/toast.git"

Remarks
=======

REST is more than some pretty URIs, the use of the HTTP verbs and
response codes. It's on the Toast user to invent meaningful media
types that control the application's state and introduce
semantics. With toast you can build REST services or tightly coupled
server-client applications, which ever suits the task best. That's why
TOAST stands for:

>  **TOast Ain't reST**

Summary
=======

Toast is an extension to Ruby on Rails to build web services with low
programming effort in coherent way.  Toast exends ActiveRecord such
that each model can be declared to be a web resource, exposing defined
attributes for reading and writing using HTTP.

Its main features are:

  * declaration of web resources based on ActiveRecord models
  * generic controller handles all actions
  * automated routing
  * exposing data values with JSON maps 
  * exposing associations by links (URLs)

WARNING
=======

*Be careful*: This version is experimental and probably not bullet
proof. As soon as the gem is loaded a controller with ready routing is
enabled serving the annotated model's data records through the
Toast controller.

Version 1.0.0 of Toast will mark a production ready implementation,
which will be finished within 2012. Until then  API/DSL changes must
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
       scope :find_some, where("number < 100")

       acts_as_resource do
         # attributes or association names
         readables :coconuts, :apple
	 writables :name, :number	 
	 
         # class methods of Banana returning an Array of Banana records
         collections :find_some, :all
       end
     end

The above definition inside the `acts_as_resource` block exposes the
records of the model Banana automatically via a generic controller to
the outside world, accepting and delivering JSON representations of
the records. Let the associated models Apple and Coconut be
exposed as a resource, too:

### Get a collection
    GET /bananas
    --> 200,  '[{"uri":"http://www.example.com/bananas/23",
                 "name": "Fred",
                 "number": 33,
                 "coconuts": "http://www.example.com/bananas/23/coconuts",
                 "apple":"http://www.example.com/bananas/23/apple,
                {"uri":"http://www.example.com/bananas/24",
                  ... }, ... ]
### Get a customized collection (filtered, paging, etc.)

    GET /bananas/find_some
    --> 200, '[SOME BANANAS]'

### Get a single resource representation:
    GET /bananas/23
    --> 200,  '{"uri":"http://www.example.com/bananas/23"
                "name": "Fred",
                "number": 33,
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple": "http://www.example.com/bananas/23/apple" }'

### Get an associated collection
    "GET" /bananas/23/coconuts
    --> 200, '[{COCNUT},{COCONUT},...]',

### Update a single resource:
    PUT /bananas/23, '{"uri":"http://www.example.com/bananas/23"
                       "name": "Barney",
                       "number": 44}'
    --> 200,  '{"uri":"http://www.example.com/bananas/23"
                "name": "Barney",
                "number": 44,
                "coconuts": "http://www.example.com/bananas/23/coconuts",
                "apple": "http://www.example.com/bananas/23/apple"}'

### Create a new record
    "POST" /bananas,  '{"name": "Johnny",
                        "number": 888}'
    --> 201,  {"uri":"http://www.example.com/bananas/102"
               "name": "Johnny",
               "number": 888,
               "coconuts": "http://www.example.com/bananas/102/coconuts" ,
               "apple": "http://www.example.com/bananas/102/apple }

### Create an associated record
    "POST" /bananas/23/coconuts, '{COCONUT}'
    --> 201,  {"uri":"http://www.example.com/coconuts/432,
               ...}

### Delete records
    DELETE /bananas/23
    --> 200

More details and configuration options are documented in the manual.

Installation
============

With bundler

    gem "toast"

the latest Git:

    gem "toast", :git => "https://github.com/robokopp/toast.git"	

Test Suite
==========

In `test/rails_app` you can find a rails application with tests. To run
the tests you need to

0. Install the *jeweler* gem:

        gem install jeweler

1. install the toast gem from this git clone:

        rake install

2. initialize the test application

        cd test/rails_app
        bundle install

3. Now you can run the test suite from within the test application

        rake

   Or you may call `rake test` from the root directory of the working
   copy. This will reinstall the toast gem before running tests
   automatically.


Remarks
=======

REST is more than some pretty URIs, the use of the HTTP verbs and
response codes. It's on the Toast user to invent meaningful media
types that control the application's state and introduce
semantics. With toast you can build REST services or tightly coupled
server-client applications, which ever suits the task best. That's why
TOAST stands for:

>  **TOast Ain't reST**

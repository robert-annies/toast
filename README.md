Summary
=======

Toast is an extension to Ruby on Rails that lets you expose any
ActiveRecord model as a resource according to the REST paradigm. The
representation format is JSON.

In contrast to other plugins, gems and Rails' inbuilt REST features
toast takes a data centric approach: Tell the model to be a resource
and what attributes and associations are to be exposed. That's it. No
controller boiler plate code for every model, no routing setup.

Toast is a Rails engine that runs one generic controller and a sets up
the routing to it according to the definition in the models, which is
denoted using a block oriented DSL.

REST is more than some pretty URIs, the use of the HTTP verbs and
response codes. It's on the toast user to invent media types that
control the application's state and introduce semantics. With toast you
can build REST services or tightly coupled server-client applications,
which ever suits the task best. That's why TOAST stands for:

>  **TOast Ain't reST**

*Be careful*: This version is experimental and probably not bullet
proof. As soon as the gem is installed a controller with ready routing
is enabled serving the annotated model's data records for reading,
updating and deleting. There are no measures to prevent XSS and CSFR
attacks.

Example
=======

Let the table `bananas` have the following schema:
     create_table "bananas", :force => true do |t|
       t.string   "name"
       t.integer  "number"
       t.string   "color"
       t.integer  "apple_id"
     end

and let a corresponding model class have a *resourceful_model* annotation:
     class Banana < ActiveRecord::Base
       belongs_to :apple
       has_many :coconuts
       scope :find_some, where("number < 100")

       resourceful_model do
         # attributes or association names
         fields :name, :number, :coconuts, :apple

         # class methods of Banana returning an Array of Banana records
         collections :find_some, :all
       end
     end

The above definition inside the `resourceful_model` block exposes the
records of the model Banana automatically via a generic controller to
the outside world, accepting and delivering JSON representations of
the records. Let the associated models Apple and Coconut be
exposed as a resource, too.

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

### Get a associated collection
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

More details and configuration options are documented in the manual... (_comming soon_)

Installation
============

    git clone git@github.com:robokopp/toast.git
    cd toast
    rake install


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

3. Now you call 'rake' from within the test application

        rake

   Or you may call `rake test` from the root directory of the working
   copy. This will reinstall the toast gem before running tests
   automatically.

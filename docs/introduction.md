# Basics

Toast is a Rack application that hooks into Ruby on Rails providing a REST
interface for ActiveRecord models. For each model a HTTP interface can
be configured. Using Toast's configuration DSL one declares which of its attributes are
exposed, which are readable and/or writable using white lists.

         Web Service Provider                    Web Service Consumer

           -----------------                      -----------------
           |    Toast      |  <--HTTP/REST-->     | AJAX app,     |
           -----------------                      | mobile app,   |
           |         |     \                      | Java app, etc.|
    ----------- ----------- -----------           -----------------
    | Model A | | Model B | | Model C |
    ----------- ----------- ----------

Toast dispatches any request to the right model class by using naming
conventions. That way a model can be exposed on the web
by a simple configuration file under `config/toast-api/coconut.rb`:

{% highlight ruby %}
expose(Coconut) {
  readables   :color, :weight

  via_get { # for GET /coconut/ID
    allow do |user, coconut, uri_params|
      user.is_admin?
    end
  }

  collection(:all) {
    via_get {  # for GET /coconuts
      allow do |user, coconut, uri_params|
        user.is_admin?
      end
    }
  }
}
{% endhighlight %}

This exposes the model Coconut. Toast would respond like this:

    GET /coconuts
    --> 200 OK
    --> [{"self":"https://www.example.com/coconuts/1","color":...,"weight":...},
         {"self":"https://www.example.com/coconuts/2","color":...,"weight":...},
         {"self":"https://www.example.com/coconuts/3","color":...,"weight":...}]

given there are 3 rows in the table _coconuts_. Note that this request
translates to the ActiveRecord call `Coconut.all`, hence the exposition of the
`all` collection. Each of the URIs in the response will fetch the
respective Coconut instances:

    GET /coconut/2
    --> 200 OK
    --> {"self":   "https://www.example.com/coconuts/2",
         "color": "brown",
         "weight": 2.1}

`color` and `weight` were declared in the `readables` list. That
means these attributes are exposed via GET requests, but not
updatable by PATCH requests. To allow that attributes must be
declared writable:

{% highlight ruby %}
expose(Coconut) {
  readables :color
  writables :weight
}
{% endhighlight %}

POST and DELETE operations must be allowed explicitly:

{% highlight ruby %}
expose(Coconut) {
  readables :color, :weight
  
  via_get { # for GET /coconut/ID
    allow do |user, coconut, uri_params|
      user.is_admin?
    end
  }

  via_delete { # for DELETE /coconut/ID
    allow do |user, coconut, uri_params|
      user.is_admin?
    end
  }

  collection(:all) {
    via_get {  # for GET /coconuts
      allow do |user, coconut, uri_params|
        user.is_admin?
      end
    }

    via_post {  # for POST /coconuts
      allow do |user, coconut, uri_params|
        user.is_admin?
      end
    }
  }
}
{% endhighlight %}

The above permits to POST a new record (== `Coconut.create(...)` and
to DELETE single instances (== `Coconnut.find(id).destroy`):

    POST /coconuts
    <-- {"color": "yellow",
         "weight": 42.0}
    --> 201 Created
    --> {"self":   "https://www.example.com/coconuts/4",
         "color": "yellow",
         "weight": 42.0}

    DELETE /coconut/3
    --> 200 OK

Nonetheless exposing associations will render your entire data
model (or parts of it) a complete web-service. Associations will be
represented as URIs via which the associated resource(s) can be fetched:

{% highlight ruby %}
class Coconut < ActiveRecord::Base
  belongs_to :tree
  has_many :consumers
end
{% endhighlight %}

together with `config/toast-api/coconut.rb`:

{% highlight ruby %}
expose(Coconut) {
  readables :color, :weight

  association(:tree) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:consumers) {
    via_get {
      allow do |user, coconut, uri_params|
        user.role == 'admin'
      end
    }

    via_post {
      allow do |user, coconut, uri_params|
        user.role == 'admin'
      end
    }
  }
}
{% endhighlight %}

    GET /coconut/2
    --> 200 OK
    --> {"self":       "https://www.example.com/coconuts/2",
         "tree":      "https://www.example.com/coconuts/2/tree",
         "consumers": "https://www.example.com/consumers",
         "color":     "brown",
         "weight":    2.1}


## Representation

Toast's JSON representation is very minimal. As you can see above it does not have any qualification of the properties. Data and links and even structured property value are possible. There are other standards like [HAL](http://stateless.co/hal_specification.html), [Siren](https://github.com/kevinswiber/siren), [Collection+JSON](http://amundsen.com/media-types/collection/) or [JSON API](http://jsonapi.org) on that matter you may also consider. 

Toast's key ideas and distinguishing features are: Simplicity and Opaque URIs. 

The JSON representation was guided by the idea that any client(/-programmer) must know the representation of each resource by documentation anyway, so there is no need to nest links in a 'links' sub structure like JSON API does. 

The only rules for Toast's JSON representation are:

* The `self` property is the canonical URI (see below) of the model/resource
* Link properties are named like ActiveRecord associations in the model and are not in non-canonical form
* Data properties are named as the corresponding attributes of the model. They can contain any type and also structured data (serialized by AR or self constructed).

## URIs

Toast treats URIs generally as opaque strings, meaning that it only uses complete URLs and has no concept of "URL templates" for processing. Such templates may only appear in the documentation.

The canonical form of a URI for a model/resource is: `https://<HOST>/<PATH>/<RESOURCE>/<ID>?<PARAMS>`, where

* `https://<HOST>` is FQDN.
* `<PATH>` is an optional path segment,
* `<RESOURCE>` is name of the resource/model
* `<ID>` is a string of digits: `[0-9]+`,
* `<PARAMS>` is an optional list of query parameters

Association URIs composed like: `<CANONICAL>/<ASSOCIATION>?<PARAMS>`, where

* `<CANONICAL>` is as defined above
* `<ASSOCIATION>` is the name a models association (`has_many`, `belongs_to`, ...)

Root collection URIs are also provided: `https://<HOST>/<PATH>/<RESOURCES>?<PARAMS>`. The string  `<RESOURCES>` is named after a class method of a model that returns a relation to a collection of instances of the same model.

## Association Treatment

Model instances link each other and construct a web of model instances/resources. The web is conveyed by URIs that can be traversed by GET request. All model association that are exposed appear in the JSON response as a URL, nothing else (embedding can be achieved through regular data properties).

Association properties never change when associations change, because they don't use the canonical URI form.

They can be used to issue a

* a POST request to create a new resource + linking to the base resource,
* a DELETE request to delete a model instance/resource,
* a LINK request in order to link existing model instances/resources using a second canonical URI or
* a UNLINK request in order to remove a association/link between model instances/resources without deleting a model instance/resource.

All these actions are directly mapped to the corresponding ActiveRecord calls on associations.

# Directive Handler

`handler` defines a block of run-time code that should be executed in
place of a default handler when processing a HTTP request.

The default handlers are the core of Toast. They implement the action
triggered by API calls, which work on ActiveRecord objects and their
associations. There are 13 handlers defined, which are documented
here.

All of them can be overridden by the `handler` directive as
necessary.

`handler` may appear under following directives:

* [`via_get`](via_get)
* [`via_patch`](via_put)
* [`via_delete`](via_delete)
* [`via_post`](via_post)
* [`via_link`](via_link)
* [`via_unlink`](via_unlink)

## The Handler Matrix

Follow the links in the matrix to see how the handler is
implemented. Empty cells don't have a handler, because not
all combinations make sense.

|                           | GET                 | PATCH               | POST                | DELETE          | LINK              | UNLINK              |
|----------------------:    | :------------------:| :---------------: | :-----------------: | :-------:       | :-----:           | :-------:           |
| **single**                | [->](#get_single)   |                   |                     |                 |                   |                     |
| **collection**            | [->](#get_coll)     |                   | [->](#post_coll)    |                 |                   |                     |
| **singular association**  | [->](#get_sassoc)   |                   |                     |                 | [->](#link_sassoc)| [->](#unlink_sassoc)|
| **plural association**    | [->](#get_passoc)   |                   | [->](#post_passoc)  |                 | [->](#link_passoc)| [->](#unlink_passoc)|
| **canonical**             | [->](#get_canon)    | [->](#put_canon)  |                     | [->](#del_canon)|                   |                     |


## Handlers

<a name="get_single"/>

# GET Single

<!-- [F.1] -->
Fetch a single record using a models class method.

*Default Handler:*

{% highlight ruby %}
handler do |uri_params|
  {MODEL}.{NAME}
end
{% endhighlight %}

, where

* `{MODEL}` is the exposed model-class and
* `{NAME}` is the name of a class method returning an instance of the model.
* `uri_params` [Hash] all parameters of the request URI

*Example:*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  def self.richest
    order("net_value DESC").first
  end
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose Person {
  readables :name, :net_value
  single :richest {
    via_get {
      allow do |*args|
        true
      end
      ## implicit Handler:
      # handler do |uri_params|
      #   Person.richest
      # end
    }
  }
}
{% endhighlight %}

Request:

    GET /people/richest
    -> { :name => "Uncle Scrooge",
         :net_value => 100000000000000000000,
         :self => "https://example.fernwerk.net/people/394" }

*End Example*

<a name="get_coll"/>

# GET Collection

<!-- [F.2] -->

Fetch an Array of records using a models class method (scope)

*Default Handler*
{% highlight ruby %}
handler do |uri_params|
  {MODEL}.{NAME}
end
{% endhighlight %}

, where

* `{MODEL}` is the exposed model-class and
* `{NAME}` is the name of the collection
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  def self.first_letter_a
    where("name LIKE 'a%'")
  end
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose Person {
  readables :name
  collection :first_letter_a {
    via_get {
      allow do |*args|
        true
      end
      ## implicit Handler:
      # handler do |uri_params|
      #   Person.first_letter_a
      # end
    }
  }
}
{% endhighlight %}

Request:

    GET /people/first_letter_a
    -> [{ :name => "Abraham", :self => "https://example.fernwerk.net/people/1937" },
        { :name => "Alfons", :self => "https://example.fernwerk.net/people/19378" },
          ... ]

*End Example*


<a name="get_sassoc"/>

# GET Singular Association

<!-- [F.3] -->

Fetch a single resource/model-instance from a model association

*Default Handler*
{% highlight ruby %}
handler do |source, uri_params|
  source.{NAME}
end
{% endhighlight %}

, where

* `source` [ActiveRecord::Base] is a model-instance that corresponds to the request URI
* `uri_params` [Hash] all parameters of the request URI
* `{NAME}` is the name of the association with type `:has_one` or `:belongs_to`


*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
      ## implicit Handler:
      # handler do |source, uri_params|
      #   source.group
      # end
    }
  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

{% endhighlight %}

Request:

    GET /people/1937/group
    -> { :name => "Clients",
         :self => "https://example.fernwerk.net/groups/23",
         :members => "https://example.fernwerk.net/groups/23/members"}

*End Example*

<a name="get_passoc"/>

# GET Plural Association

<!-- [F.4] -->

Fetch an array of resources/model-instances from a model associatiion.

*Default Handler*
{% highlight ruby %}
handler do |source, uri_params|
  source.{NAME}
end
{% endhighlight %}

, where

* `source` [ActiveRecord::Base] is a model-instance that corresponds to the request URI
* `uri_params` [Hash] all parameters of the request URI
* `{NAME}` is the name of the association with type `:has_many` or `:has_and_belongs_to`

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
      ## Implicit handler
      # handler do |source, uri_params|
      #   source.members
      # end
    }
  }
}

{% endhighlight %}

Request:

    GET /groups/23/members
    -> [
         { :name => "Alfons",
           :self => "https://example.fernwerk.net/people/2947",
           :group => "https://example.fernwerk.net/people/2947/group" },
         { :name => "Bert",
           :self => "https://example.fernwerk.net/people/293",
           :group => "https://example.fernwerk.net/people/293/group" }
       ]

*End Example*

<a name="get_canon"/>

# GET Canonical URI

<!-- [F.5] -->

Fetch a resource/model-instance by it's canonical URI, which is a unique ID for it.

*Default Handler*
{% highlight ruby %}
handler do |model_instance, uri_params|
  model_instance
end
{% endhighlight %}

, where

* `model_instance` is a ActiveRecord::Base object or descendant
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Group) {
  readables :name
  association(:members) {
    via_get {
      allow do |*args|
        true
      end
      ## implicit handler
      # handler do |model_instance, uri_params|
      #   model_instance
      # end
    }
  }
{% endhighlight %}

Request:

    GET /groups/23
    -> { :name => "Clients",
         :self => "https://example.fernwerk.net/groups/23",
         :members => "https://example.fernwerk.net/groups/23/members"}

*End Example*

<a name="put_canon"/>

# PATCH Canonical URI

<!-- [F.6] -->

Update a resource/model-instance by it's canonical URI.

*Default Handler*
{% highlight ruby %}
handler do |model_instance, payload, uri_params|
  model_instance.update payload
end
{% endhighlight %}

, where

* `model_instance` is a ActiveRecord::Base object or descendant
* `payload` [Hash], the decoded request body (from JSON), all non-writable attributes were cleared before.
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  has_and_belongs_to_many :groups
  def group_names
    groups.map(&:name).join(' ')
  end
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  writables :first_namue, :last_name
  readables :group_names
  via_get {
    allow do |*args|
      true
    end
  }
  via_patch {
    allow do |*args|
      true
    end
    ## implicit handler
    # handler do |model_instance, payload, uri_params|
    #   model_instance.update payload
    # end
  }
}
{% endhighlight %}

Request:

    GET /people/5419
    -> { :firs_name => "John",
         :last_name => "Foe",
         :self => "https://example.fernwerk.net/people/5419",
         :group_names => "Friends ToastCommitters"}

    PATCH /people/5419, {"first_name":"John", "last_name":"Doe"}
    -> { :firs_name => "John",
         :last_name => "Doe",
         :self => "https://example.fernwerk.net/people/5419",
         :group_names => "Friends ToastCommitters"}

*End Example*

<a name="post_coll"/>

# POST (to) Collection

<!-- [F.7] -->

Create a new resource/model-instance of the collections type by the collections URI.

Note, that POST is only configurable for the `all` collection
(URIs: `/{MODEL}` or `/{MODEL}/all`) and not for other collections/scopes of
the model class.

*Default Handler*
{% highlight ruby %}
handler do |payload, uri_params|
  {MODEL}.create payload
end
{% endhighlight %}

, where

* `{MODEL}` is a the model-class
* `payload` is a Hash, the decoded request body (JSON), all non-writable attributes were cleared before.
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  def self.first_letter_a
    where("name LIKE 'a%'")
  end
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  writables :first_name, :last_name
  collection(:all) {
    via_post { # allowed in collection(:all) only
      allow do |*args|
        true
      end
      ## implicit handler
      # handler do |payload, uri_params|
      #   Person.create payload
      # end
    }
  }
}
{% endhighlight %}

Request:

    POST /people, {"first_name": "Henry", "last_name": "Conrad"}
    -> { :firs_name => "Henry",
         :last_name => "Conrad",
         :self => "https://example.fernwerk.net/people/875",
         :group_names => ""}

*End Example*

<a name="post_passoc"/>

# POST (to) Plural Association

<!-- [F.8] -->

Create a new resource/model-instance via a association. The record is created and linked to the association to which the request is sent.

*Default Handler*
{% highlight ruby %}
handler do |source, payload, uri_params|
  source.{NAME}.create payload
end
{% endhighlight %}

, where

* `payload` [Hash] is the data for the new model-instance
* `uri_params` [Hash] all parameters of the request URI
* `{NAME}` [String] is the name of an asssociation of type `:has_many` or `:has_and_belongs_to_many`.

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
    via_post {
      allow do |*args|
        true
      end
      ## Implicit handler
      # handler do |source, payload, uri_params|
      #   source.members.create payload
      # end
  }
}

{% endhighlight %}

Request:

    GET /groups/23/members
    -> [
         { "name":  "Alfons",
           "self":  "https://example.fernwerk.net/people/2947",
           "group": "https://example.fernwerk.net/people/2947/group" },
         { "name":  "Bert",
           "self":  "https://example.fernwerk.net/people/293",
           "group": "https://example.fernwerk.net/people/293/group" }
       ]

    POST /groups/23/members, {"name":"Conrad"}
    -> { "name" : "Conrad",
         "self" : "https://example.fernwerk.net/people/20348"
         "group" :   https://example.fernwerk.net/people/20348/group" }

    GET /groups/23/members
    -> [
         { "name":  "Alfons",
           "self":  "https://example.fernwerk.net/people/2947",
           "group": "https://example.fernwerk.net/people/2947/group" },
         { "name":  "Bert",
           "self":  "https://example.fernwerk.net/people/293",
           "group": "https://example.fernwerk.net/people/293/group" },
         { "name" : "Conrad",
           "self" : "https://example.fernwerk.net/people/20348"
           "group" :   https://example.fernwerk.net/people/20348/group" }
       ]


*End Example*

<a name="del_canon"/>

# DELETE Canonical URI

<!-- [F.9] -->

Delete a resource/model-instance by it's canonical URI.

*Default Handler*
{% highlight ruby %}
handler do |model_instance, uri_params|
  model_instance.destroy
end
{% endhighlight %}

, where

* `model_instance` is a ActiveRecord::Base object or descendant
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  writables :first_namue, :last_name

  via_delete {
    allow do |*args|
      true
    end
    ## implicit handler
    # handler do |model_instance, uri_params|
    #   model_instance.destroy
    # end
  }
}
{% endhighlight %}

Request:

    DELETE /people/5419
    -> "200 OK"

*End Example*

<a name="link_sassoc"/>

# LINK Singular Association

<!-- [F.10] -->

Associate resources/model-instances via a singular model associations
or update such associations.

*Default Handler*
{% highlight ruby %}
handler do |source, target, uri_params|
  source.{NAME} = target
  source.save
end
{% endhighlight %}

, where

* `{NAME}` is the name of the association (type: *has_one*, *belongs_to*)
* `source` is base model-instance owning the association
* `target` is model-instance which corresponds to URI found in the link header
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
      via_link {
        allow do |*args|
          true
        end
        ## implicit handler
        # handler do |source, target, uri_params|
        #  source.group = target
        #  source.save
        # end
      }
    }
  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

{% endhighlight %}

Request:

    GET /people/1937/group
    -> "404 Not Found"

    LINK /people/1937/group, Link: <https://example.fernwerk.net/groups/23>,rel='related'
    -> 200 OK

    GET /people/1937/group
    -> { "name": "Clients",
         "self": "https://example.fernwerk.net/groups/23",
         "members": "https://example.fernwerk.net/groups/23/members"}

*End Example*

<a name="link_passoc"/>

# LINK Plural Association #

<!-- [F.11] -->

Associate resources/model-instances via plural model associations
or update such associations.

*Default Handler*
{% highlight ruby %}
handler do |source, target, uri_params|
  source.{NAME} << target
end
{% endhighlight %}

, where

* `{NAME}` is the name of the association (type: *has_many*, *has_and_belongs_to_many*)
* `source` is base model-instance owning the association
* `target` is model-instance which corresponds to URI found in the link header
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
    }

  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
    via_link {
      allow do |*args|
        true
      end
      ## implicit handler
      # handler do |source, target, uri_params|
      #  source.members << target
      # end
    }
  }
}

{% endhighlight %}

Request:

    GET /group/781/members
    -> [{"name": "Carlo", "self" : "https://example.fernwerk.net/people/14"}]

    LINK /group/781/members, Link: <https://example.fernwerk.net/people/20>,rel='related'
    -> 200 OK

    GET /group/781/members
    -> [{"name": "Carlo", "self": "https://example.fernwerk.net/people/14"},
        {"name": "Anna", "self": "https://example.fernwerk.net/people/20"}]

*End Example*

<a name="unlink_sassoc"/>

# UNLINK Singular Association

<!-- [F.12] -->

Remove links between resources/model-instances via singular model
associations.

Note that, the target to be unlinked must be passed with the Link
header. If it's not the currently linked one the request has no
effect.

*Default Handler*
{% highlight ruby %}
handler do |source, target, uri_params|
  if source.{NAME} == target
    source.{NAME} = nil
    source.save
  end
end
{% endhighlight %}

, where

* `{NAME}` is the name of the association (type: *has_one*, *belongs_to*)
* `source` is base model-instance owning the association
* `target` is model-instance (to be unlinked) which corresponds to URI found in the link header
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person){
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
      via_unlink {
        allow do |*args|
          true
        end
        ## implicit handler
        # handler do |source, target, uri_params|
        #   if source.group == target
        #     source.group = nil
        #     source.save
        #   end
        # end
      }
    }
  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

{% endhighlight %}

Request:

    GET /people/1937/group
    -> { "name": "Clients",
         "self": "https://example.fernwerk.net/groups/23",
         "members": "https://example.fernwerk.net/groups/23/members"}

    UNLINK /people/1937/group, Link: <https://example.fernwerk.net/groups/23>,rel='related'
    -> 200 OK

    GET /people/1937/group
    -> "404 Not Found"


*End Example*

<a name="unlink_passoc"/>

# UNLINK Plural Association #

<!-- [F.13] -->

Remove links between resources/model-instances via plural model associations.

*Default Handler*
{% highlight ruby %}
handler do |source, target, uri_params|
  source.{NAME}.delete(target)
end
{% endhighlight %}

, where

* `{NAME}` is the name of the association (type: *has_many*, *has_and_belongs_to_many*)
* `source` is base model-instance owning the association
* `target` is model-instance which corresponds to URI found in the link header
* `uri_params` [Hash] all parameters of the request URI

*Example*

Model:

{% highlight ruby %}
class Person < ApplicationRecord
  belongs_to :group
end
class Group < ApplicationRecord
  has_many :members, class_name: "Person"3
end
{% endhighlight %}

Toast Configuration:

{% highlight ruby %}
expose(Person) {
  readables :name
  association :group {
    via_get {
      allow do |*args|
        true
      end
    }

  }
}
expose(Group) {
  readables :name
  association :members {
    via_get {
      allow do |*args|
        true
      end
    }
    via_unlink {
      allow do |*args|
        true
      end
      ## implicit handler
      # handler do |source, target, uri_params|
      #  source.members.delete(target)
      # end
    }
  }
}

{% endhighlight %}

Request:

    GET /group/781/members
    -> [{"name": "Carlo", "self": "https://example.fernwerk.net/people/14"},
        {"name": "Anna", "self": "https://example.fernwerk.net/people/20"}]

    UNLINK /group/781/members, Link: <https://example.fernwerk.net/people/14>,rel='related'
    -> 200 OK

    GET /group/781/members
    -> [{"name": "Anna", "self" : "https://example.fernwerk.net/people/20"}]

*End Example*

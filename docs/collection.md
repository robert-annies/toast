---
layout: page
title: Directive 'collection'
---

`collection({COLL}) { ... }`

Declares that a model exposes a collection of instances. `{COLL}` is the name of a class method or scope of the model. Generally, they are certain subsets and/or orders of the models instances.

Collections are exposed by theur URI, which has the form:

`https://{HOST}/{PATH}/{RESOURCE}/{COLL}?{PARAMS}`, where

* `https://{HOST}` is a FQDN.
* `{PATH}` is an optional path segment (see [`expose`](expose) parameter `under:` ),
* `{RESOURCE}` is name of the resource/model (plural form)
* `{COLL}` is the name the class method or scope
* `{PARAMS}` is an optional list of query parameters

Within the block it must be declared which methods the exposed URI
accepts. This is done by the directives which have further
sub-directives for permissions and custom handlers:

* [`via_get`](via_get) <!-- [C.1]-->
* [`via_post`](via_post) <!-- [C.1] -->
* [`max_window`](max_window) <!-- [C.2] -->

The first one is to retrieve the collection the latter to create a new resource/model instance for that collection.

Note, that the special collecton `:all` can be exposed. The URIs `https://{HOST}/{PATH}/{RESOURCE}/all` and `https://{HOST}/{PATH}/{RESOURCE}` are both responding with all instances of the model.

*POST: Does this work with certain scopes and default handler? What is the handler for non-scope collections? Custom handler required?*

## Windowing

Collections are always delivered partially. If not requested otherwise
the items 0 to _max_window_ (defined in the
[global configuration file](global_config)) are delivered. To request
other ranges the HTTP header _Range_ should be used. More on the
[`max_window` page](max_window).

## Example

{% highlight ruby %}
class Person < ApplicationRecord
  scope :johns, -> { where(first_name: 'John') }
end
{% endhighlight %}
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name
  collection(:johns) {
    via_get {
      allow do |*args|
        true # allow for all
      end
    }
  }
  collection(:all) {
    via_get {
      allow do |*args|
        true # allow for all
      end
    }
  }
}
{% endhighlight %}

would yield:

`GET https://toast-examples.org/people`:
{% highlight json %}
[
    {
	"self"      : "https://toast-examples.org/people/1902",
	"first_name": "John",
	"last_name" : "Smith"
    },{
	"self"      : "https://toast-examples.org/people/23",
	"first_name": "Jakob",
	"last_name" : "Miller"
    },{
	"self"      : "https://toast-examples.org/people/87",
	"first_name": "John",
	"last_name" : "Gordon"
    }
]
{% endhighlight %}

`GET https://toast-examples.org/people/johns`:
{% highlight json %}
[
    {
	"self"      : "https://toast-examples.org/people/1902",
	"first_name": "John",
	"last_name" : "Smith"
    },{
	"self"      : "https://toast-examples.org/people/87",
	"first_name": "John",
	"last_name" : "Gordon"
    }
]
{% endhighlight %}

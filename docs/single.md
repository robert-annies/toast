# Directive 'single'

`single({SINGLE}) { ... }`

Declares that a model exposes a class method returning a single instance. `{SINGLE}` is the name of a class method (as Symbol).

Singles are exposed by their URI, which has the form:

`https://{HOST}/{PATH}/{RESOURCE}/{SINGLE}?{PARAMS}`, where

* `https://{HOST}` is a FQDN.
* `{PATH}` is an optional path segment (see [`expose`](expose) parameter `under:` ),
* `{RESOURCE}` is name of the resource/model
* `{SINGLE}` is the name the class method
* `{PARAMS}` is an optional list of query parameters

Within the block it must be declared which methods the exposed URI
accepts. This is done by the directives which have further
sub-directives for permissions and custom handlers:

* [`via_get`](via_get) <!-- [E.1] -->

Only GET is available. For updates or deletions use the canonical URI of the resource/model instance.

Note, that also pre-defined methods of ActiveRecord can be exposed. E.g. `:first`, `:second`, `:last`.

{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name
  single(:first) {
    via_get {
      allow do |*args|
        true # allow for all
      end
    }
  }
}
{% endhighlight %}

gives:

`GET https://toast-examples.org/people/first`:
{% highlight json %}
{
    "self"      : "https://toast-examples.org/people/1",
    "first_name": "John",
    "last_name" : "Smith"
}
{% endhighlight %}

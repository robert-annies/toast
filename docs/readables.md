# Directive 'readables'

`readables {ATTRIBUTE},{ATTRIBUTE},...`

Declares which attributes of the model are to be exposed by the JSON
representation. All listed attributes (by Symbol) are expected to be
attributes or instance methods of the model class, that are called
when the representation is built. The returned value must at least
respond to `#to_json`.

Attributes exposed with `readables` but not with
[`writables`](writables) are read-only. Attempts to update them with PATCH
are silently ignored.

The [`via_get`](via_get) and [`allow`](allow) directives are also
required to route and authorize GET requests and to
canonical URIs of resources/model-instances.

## Example

{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name, :phone
  via_get {
    allow do |*args|
      true
    end
  }
}
{% endhighlight %}

would yield a representation for `GET https://toast-examples.org/people/42`:

{% highlight json %}
{
    "self"      : "https://toast-examples.org/people/42",
    "first_name": "Jason",
    "last_name" : "Plant",
    "phone"     : "082-0193878560"
}
{% endhighlight %}

None of the attributes/properties can be changed via HTTP API.

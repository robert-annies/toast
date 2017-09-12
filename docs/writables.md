# Directive 'writables'

`writables {ATTRIBUTE},{ATTRIBUTE},...`

declares which attributes of the model are to be exposed by the JSON
representation and updatable by PATCH requests. All listed attributes
(by Symbol) are expected to be attributes or instance methods of the
model class, that are called when the representation is built or when
attributes are to be updated.

The returned value must at least respond to `#to_json`.  For virtual
attributes a setter must be defined in the model's class.

The [`via_patch`](via_put) and [`allow`](allow) directives are also
required to route and authorize PATCH requests to
canonical URIs of resources/model-instances.

## Example

{% highlight ruby %}
expose(Person) {
  writables :first_name, :last_name, :phone
  via_patch {
    allow do |*args|
      true
    end
  }
}
{% endhighlight %}

`PATCH https://example.com/people/42 {"first_name": "George"}`

would update the record and respond with:

{% highlight json %}
{
    "self"      : "https://example.com/people/42",
    "first_name": "Jason",
    "last_name" : "George",
    "phone"     : "082-0193878560"
}
{% endhighlight %}

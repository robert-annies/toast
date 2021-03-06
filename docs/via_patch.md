# Directive 'via_patch'

`via_patch { ... }`

The directive activates the routing of PATCH requests to the application. PATCH requests update single resources/model-instances according to the provided JSON payload.

`via_patch` may appear inside the directive [`expose`](expose).

The directive's block contains [`allow`](allow) (required) and [`handler`](handler) directives (optional), which define run-time code to decide on authorization and contain custom business logic if the built-in default handler is not appropriate.


# Example
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name
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
    #   model_instance.update! payload
    # end
  }
}
{% endhighlight %}

Request:

    PATCH https://example.com/people/44
      {"first_name": "Johnny", "last_name": "Gold"}

Response:
{% highlight json %}
{
    "self"      : "https://example.com/people/44",
    "first_name": "Johnny",
    "last_name" : "Gold"
}
{% endhighlight %}

# Directive 'via_delete'

`via_delete { ... }`

The directive activates the routing of DELETE requests to the application. DELETE requests remove single resources/model-instances.

`via_delete` may appear inside the directive [`expose`](expose).

The directive's block contains [`allow`](allow) <!-- [D.1] -->
(required) and [`handler`](handler) <!-- [D.2] --> directives (optional), which define run-time code to decide on authorization and contain custom business logic if the built-in default handler is not appropriate.

# Example
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name

  via_get {
    allow do |*args|
      true
    end
  }

  via_delete {
    allow do |*args|
      true
    end

    ## implicit handler
    # handler do |model_instance, uri_params|
    #   model_instance.destroy!
    # end
  }
}
{% endhighlight %}

Request:

    DELETE https://toast-examples.org/people/44

Removed the resource/model-instance.

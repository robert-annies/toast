---
layout: page
title: Directive 'via_get'
---

`via_get { ... }`

The directive activates the routing of GET requests to the application. Depending on it's context GET requests deliver arrays of or single resources/model-instances as JSON data.

`via_get` may appear inside the directives:

* [`expose`](expose)
* [`collection`](collection)
* [`association`](association)
* [`single`](single)

The directive's block contains [`allow`](allow) (required) <!-- [D.1] -->
and [`handler`](handler) directives (optional) <!-- [D.2] -->,
which define run-time code to decide on authorization and contain
custom business logic if the built-in default handlers are not
appropriate.

# Example
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name

  via_get {
    allow do |*args|
      true
    end

    ## implicit handler
    # handler do |model, uri_params|
    #   model
    # end
  }
}
{% endhighlight %}

Request:

`GET https://toast-examples.org/people/44`

Response:
{% highlight json %}
{
    "self"      : "https://toast-examples.org/people/44",
    "first_name": "John",
    "last_name" : "Silver"
}
{% endhighlight %}

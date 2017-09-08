---
layout: page
title: Directive 'via_post'
---

`via_post { ... }`

The directive activates the routing of POST requests to the application. POST requests send JSON data in order to create new resources/model-instances on the server and return the created resource.

`via_post` may appear inside the directives:

* [`collection`](collection)
* [`association`](association) (plural)

The directive's block contains [`allow`](allow) <!-- [D.1] --> (required) and
[`handler`](handler) <!-- [D.2] --> directives (optional), which define run-time code to decide on authorization and contain custom business logic if the built-in default handlers are not appropriate.

To create new resources the POST request's URI must specify the base resource under which the new resource shall be available. This can be either the `:all` collection or a plural association.

# Example
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name
  collection(:all) {
    via_get {
      allow do |*args|
        true
      end
    }

    via_post {
      allow do |*args|
        true
      end

      ## implicit handler
      # handler do |payload, uri_params|
      #   Person.create! payload
      # end
    }
  }

  association(:posts) {
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
      # handler do |person, payload, uri_params|
      #   person.posts.create! payload
      # end
    }
  }
}

expose(Post) {
  readables :title, :text
  via_get {
    allow do |*args|
      true
    end
  }

  association(:author) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}
{% endhighlight %}

Request:

    POST https://toast-examples.org/people
      {"first_name": "Elinor", "last_name": "Langosh"}

Response:

{% highlight json %}
{
    "self"      : "https://toast-examples.org/people/102",
    "posts"     : "https://toast-examples.org/people/102/posts",
    "first_name": "Elinor",
    "last_name" : "Langosh"
}
{% endhighlight %}

Request:

    POST https://toast-examples.org/people/102/posts
      {"title": "My First Toast", "text": "It was a bit dry."}

Response:

{% highlight json %}
{
    "self"      : "https://toast-examples.org/posts/2957",
    "author"    : "https://toast-examples.org/posts/2957/author",
    "title"     : "My First Toast",
    "text"      : "It was a bit dry."
}
{% endhighlight %}

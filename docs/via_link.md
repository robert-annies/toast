# Directive 'via_link'

`via_link { ... }`

The directive activates the routing of LINK requests to the application. LINK requests update link meta data of a resource. I.e an association is establish between two existing resources.

`via_link` may appear inside the block of directive [`association`](association).

The directive's block contains [`allow`](allow) <!-- [D.1] --> (required) and [`handler`](handler)  <!-- [D.2] --> directives (optional), which define run-time code to decide on authorization and contain custom business logic if the built-in default handlers are not appropriate.

The LINK-requests URI must be that of an association (a.k.a _context IRI_) and the HTTP header _Link_ must contain the URI of the resource to be linked to the association (a.k.a _target IRI_). The relation type should be _related_ as defined in [RFC&nbsp;4287 The Atom Syndication Format](http://tools.ietf.org/html/rfc4287).

See also [RFC&nbsp;5988 Web Linking](https://tools.ietf.org/html/rfc5988)

See also this note on [LINK and UNLINK](link_and_unlink)



# Example
{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name
  association(:country) {
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
      #  source.country = target
      #  source.save!
      # end
    }
  }
}

expose(Country) {
  readables :name, :languages
  via_get {
    allow do |*args|
      true
    end
  }

  association(:people) {
    via_get {
      allow do |*args|
        true
      end
    }

    via_link {
      allow do |*args|
        true
      end

      ## implicit hander
      # handler do |source, target, uri_params|
      #  source.people << target
      # end
    }
  }
}
{% endhighlight %}

Request:

    LINK https://toast-examples.org/people/102/country
         Link: <https://toast-examples.org/countries/40>; rel="related"

Response: `200 OK`

Request:

    GET https://toast-examples.org/people/102/country

Response:

{% highlight json %}
{
    "self"      : "https://toast-examples.org/countries/40",
    "people"    : "https://toast-examples.org/countries/40/people",
    "name"      : "Switzerland",
    "languages" : ["fr","de","it"]
}
{% endhighlight %}

------

Request:

    LINK https://toast-examples.org/countries/40/people
         Link: <https://toast-examples.org/people/44>; rel="related"

Response: `200 OK`

Request:
    GET https://toast-examples.org/countries/40/people

{% highlight json %}
[
    {
	"self"      : "https://toast-examples.org/people/44",
	"country"   : "https://toast-examples.org/people/44/countries",
	"first_name": "Johnny",
	"last_name" : "Gold"
    } , ...
]
{% endhighlight %}

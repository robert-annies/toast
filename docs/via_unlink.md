# Directive 'via_unlink'

`via_unlink { ... }`

The directive activates the routing of UNLINK requests to the application. UNLINK requests update link meta data of a resource. I.e an association between two existing resources is removed, while no resources are removed.

`via_unlink` may appear inside the block of directive [`association`](association).

The directive's block contains [`allow`](allow) <!-- [D.1] --> (required) and [`handler`](handler)  <!-- [D.2] --> directives (optional), which define run-time code to decide on authorization and contain custom business logic if the built-in default handlers are not appropriate.

The UNLINK-requests URI must be that of an association (a.k.a _context IRI_) and the HTTP header _Link_ must contain the URI of the resource to be un-linked from the association (a.k.a _target IRI_). The relation type should be _related_ as defined in [RFC&nbsp;4287 The Atom Syndication Format](http://tools.ietf.org/html/rfc4287).

See also [RFC&nbsp;5988 Web Linking](https://tools.ietf.org/html/rfc5988)

See also this note on [UNLINK and UNUNLINK](link_and_unlink)

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

    via_unlink {
      allow do |*args|
        true
      end

      ## implicit handler
      # handler do |source, target, uri_params|
      #   if source.country == target
      #     source.country = nil
      #     source.save!
      #   end
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

    via_unlink {
      allow do |*args|
        true
      end

      ## implicit handler
      # handler do |source, target, uri_params|
      #  source.people.delete(target)
      # end
    }
  }
}
{% endhighlight %}

Let the resource `countries/40` be associated with the resource `people/102/country` (i.e.
`Person.find(102).country == Country.find(40)`).

Request:

    UNLINK https://example.com/people/102/country
           Link: <https://example.com/countries/40>; rel="related"

Response: `200 OK`

Request:

    GET https://example.com/people/102/country

Response: `404 Not Found`

------


Let the resource `people/44` be associated with the resource `countries/40/people` (i.e.
`People.find(44).in?(Country.find(40).people) == true`).

Request:

    UNLINK https://example.com/countries/40/people
           Link: <https://example.com/people/44>; rel="related"

Response: `200 OK`

Request:
    GET https://example.com/countries/40/people

{% highlight javascript %}
[
    {
	"self"      : "https://example.com/people/76",
	"country"   : "https://example.com/people/76/countries",
	"first_name": "Karl",
	"last_name" : "Kohl"
    } ,...  // https://example.com/people/44 not in here
]
{% endhighlight %}

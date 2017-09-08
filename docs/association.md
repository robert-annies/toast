# Directive 'association'

`association({ASSOC}) { ... }`

Declares that an association of the model is to be exposed. `{ASSOC}`
is the name of an association of the _has_one_, _has_many_, _belongs_to_ or a _has_and_belongs_to_many_ type.

Associations are exposed by their URI, which has the form:

`https://{HOST}/{PATH}/{RESOURCE}/{ID}/{ASSOC}?{PARAMS}`, where

* `https://{HOST}` is a FQDN.
* `{PATH}` is an optional path segment (see [`expose`](expose) parameter `under:` ),
* `{RESOURCE}` is name of the resource/model
* `{ID}` is a string of digits: `[0-9]+`,
* `{ASSOC}` is the name the association
* `{PARAMS}` is an optional list of query parameters

Within the block it must be declared which methods the exposed URI
accepts. This is done by the directives which have further
sub-directives for permissions and custom handlers:

* [`via_get`](via_get)       <!-- [B.1] -->
* [`via_post`](via_post)     <!-- [B.1] -->
* [`via_link`](via_link)     <!-- [B.1] -->
* [`via_unlink`](via_unlink) <!-- [B.1] -->
* [`max_window`](max_window) <!-- [B.2] -->

Note that the HTTP methods PATCH and DELETE are not possbile for association URIs. These are used for canonical URLs of model instances only.

## Plural Associations

For plural associaitons (_has_many_, _has_and_belongs_to_many_) the
methods GET, POST, LINK and UNLINK are available. A GET response carries
always a JSON Array of Objects representing model instances. POST will
create a new resource/model instance and associates it with the base
resource/model. LINK and UNLINK will associate or disassociate
roesources/models. See the `via_*` directive pages for mote details.

### Windowing

Plural associations are always delivered partially. If not requested otherwise
the items 0 to _max_window_ - 1 (default is defined in the
[global configuration file](global_config)) are delivered. To request
other ranges the HTTP header _Range_ should be used. More on the
[`max_window` page](max_window).

## Singular Associations

On singluar associaitons (_has_one_, _belongs_to_) the methods GET,
LINK, UNLINK are available. A GET response will deliver the JSON
representation of a model instance, LINK/UNLINK associate other
resources or remove the association.

Singular associated resources/models cannot be updated via their
association URIs to avoid ambiguities. Use the canonical URL of the
recource (_self_ property) to use with PATCH.

## Example

{% highlight ruby %}
expose(Person) {
  readables :first_name
  association(:friends) {
    via_get {
      allow do |*args|
        true # allow for all
      end
    }
  }
}
{% endhighlight %}

would yield a JSON representation:

{% highlight json %}
{
    "self"      : "https://toast-examples.org/people/42",
    "first_name": "Jason",
    "friends"   : "https://toast-examples.org/people/42/friends"
}
{% endhighlight %}

The HTTP API provides read access to a collection of "friend" records, which are delivered as a JSON array:

`GET https://toast-examples.org/people/42/friends`:
{% highlight json %}
[
    {
	"self"      : "https://toast-examples.org/people/1902",
	"first_name": "John",
	"friends"   : "https://toast-examples.org/people/1902/friends"
    },
    {
	"self"      : "https://toast-examples.org/people/23",
	"first_name": "Jakob",
	"friends"   : "https://toast-examples.org/people/23/friends"
    }
]
{% endhighlight %}

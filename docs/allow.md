---
layout: page
title: Directive 'allow'
---

{% highlight ruby %}
allow do |auth, request_model, uri_params|
  # make decision whether to authorize or not
end
{% endhighlight %}

, where `auth` is an Object that holds authentication information,
`request_model` is the base model requested (e.g. `GET /people/72` =
`Person.find(72)`) and `uri_params` is the Hash of URI parameters if the
request URI.

All requests that are routed through Toast require an `allow` block that authorizes the requested operation. There is no default.

`allow` must appear under following directives:

* [`via_get`](via_get)
* [`via_patch`](via_put)
* [`via_delete`](via_delete)
* [`via_post`](via_post)
* [`via_link`](via_link)
* [`via_unlink`](via_unlink)

Authentication is done by Toast via the `authenticate` block in the
[`global configuration`](global_config) file.

Any result object of the `authenticate` block is passed to Toast's
authorization process, that calls the appropriate `allow` block for
the respective URI.

# Example
Often the authentication object is the identified user model. How to
identify the user is up to you (maybe by OAuth, OpenID, login/password
DB lookup, LDAP, ...)

{% highlight ruby %}
toast_settings {
  authenticate do |request|
      ActionController::HttpAuthentication::Basic.authenticate(request) do |login,password|
        user = User.find_by_login login
        user.authenticate(password)
      end
  end
}
{% endhighlight %}

The allow block could be like this to athorize the user to update an
Article that was authored by the same user.

{% highlight ruby %}
expose(Article) {
  # ...
  via_patch {
    allow do |user, article, uri_params|
      article.author == user
    end
  }
}
{% endhighlight %}

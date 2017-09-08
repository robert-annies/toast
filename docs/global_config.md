---
layout: page
title: Global Configuration
---

For settings regarding all exposed models and behavior a global configuration file is located at `config/toast-api.rb`. It has following form and default values:

{% highlight ruby %}
toast_settings {
  max_window 42
  link_unlink_via_post false

  authenticate do |request|
    false
  end
}
{% endhighlight %}

# Settings

All settings are optional.

* `max_window {SIZE}`

  Sets the global maximum window size for all
  collections/associations. See also [`max_window` directive](max_window)

* `link_unlink_via_post {true|false}`

  If `true`, switches to POST wrapped LINK and UNLINK requests. Client applications use POST requests with approriate `X-Http-method-override` and `Link` headers.

* `authenticate` block

  The block's argument is an ActionDispatch::Request object that can be used with
  Ruby on Rails included authentication methods or any custom code.

  The authenticate block is called before any request is processed. The return
  value can be any object.

  In case it's a truthy value it will be passed on to the authorization hooks
  configured for the request ([`allow` directive](allow)). In case a falsy value
  is returned (`false` or `nil`) a "401 Unauthorized" response is sent
  immediately and no `allow` hooks are called.

  Examples:

  *HTTP Basic Authentication*
  {% highlight ruby %}
     authenticate do |request|
       ActionController::HttpAuthentication::Basic.authenticate(request) do |login,password|
         user = User.find_by_login login
         user.authenticate(password)
       end
     end
  {% endhighlight %}

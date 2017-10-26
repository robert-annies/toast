# Directive 'expose'

{% highlight ruby %}
expose({MODEL}, as: {MEDIA_TYPE}, under: {PATH}) {
  {DIRECTIVE}
  {DIRECTIVE}
  ...
}
{% endhighlight %}



The `expose` stanzas are the top level configuration elements. They
declare what attributes and associations are exposed in the JSON
representation of a model instance.

For each exposed model there should be one or more `expose` stanzas,
with following arguments:

* `{MODEL}` is the model to be exposed. It must be an ActiveRecord
  or descendant.

* `{MEDIA_TYPE}` is an optional string defining the media type of the
  response. The `Content-Type` HTTP header is set to this value, that
  defaults to `application/json`.

* `{PATH}` is a slash delimited path string which is prepended to the URI path of the
  resource. Leading and trailing slashes are ignored. With path prefixes can separate your api from your other routes, to avoid collisons or you can use it for versioning. 

  For example the canonical URI of a model instance would be:

  `http://example.com/path/segment/of/your/choice/apples/8` 

  if you set 

  `expose(Apple, under: /path/segment/of/your/choice)`

* `{DIRECTIVE} ...` is a list of configuration directives to define
  the API of this model.
  Possible directives under `expose` are:

  * [`readables`](readables)      
  * [`writables`](writables)     
  * [`association`](association) 
  * [`collection`](collection)   
  * [`single`](single)           
  * [`via_get`](via_get)         
  * [`via_patch`](via_patch)
  * [`via_post`](via_post)
  * [`via_delete`](via_delete)   
  * [`via_link`](via_link)   
  * [`via_unlink`](via_unlink)   




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
  or descendant. <!-- [A.1, A.2] -->

* `{MEDIA_TYPE}` is an optional string defining the media type of the
  response. The `Content-Type` HTTP header is set to this value, that
  defaults to `application/json`.
  <!-- [A.3] -->

* `{PATH}` is a path string which is prepended to the URI of the
  resource. Leading and trailing `/` are ignored.
  <!-- [A.4] -->

* `{DIRECTIVE} ...` is a list of configuration directives to define
  the API of this model.
  Possible directives under `expose` are:


  * [`readables`](readables)      <!-- [A.6] -->
  * [`writables`](writables)      <!-- [A.5] -->
  * [`association`](association)  <!-- [A.9] -->
  * [`collection`](collection)    <!-- [A.7] -->
  * [`single`](single)            <!-- [A.8] -->
  * [`via_get`](via_get)          <!-- [A.9] -->
  * [`via_patch`](via_put)          <!-- [A.10] -->
  * [`via_delete`](via_delete)    <!-- [A.11] -->

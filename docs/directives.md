# Directives

* [`expose`](expose)
  * Expose a model via HTTP+JSON
* [`readables`](Readables)
  * Declare read-only attributes/properties
* [`writables`](writables)
  * Declare writable attributes/properties
* [`association`](association)
  * Expose model associations
* [`collection`](collection)
  * Expose model class methods returning collections
* [`single`](single)
  * Expose model class methods returning single instances
* [`via_get`](via_get)
  * Activate a GET route to a model, collection, association or single
* [`via_patch`](via_put)
  * Activate a PATCH route to a model
* [`via_post`](via_post)
  * Activate a POST route to a collection or association
* [`via_delete`](via_delete)
  * Activate a GET route to a model
* [`via_link`](via_link)
  * Activate a GET route to a association
* [`via_unlink`](via_unlink)
  * Activate a GET route to a association
* [`allow`](allow)
  * Specify authorization handler
* [`handler`](handler)
  * Override default handler for GET/PATCH/POST/DELETE/LINK/UNLINK
  requests
* [`max_window`](max_window)
  * Set the maximum window size for windowed (paginated) collections

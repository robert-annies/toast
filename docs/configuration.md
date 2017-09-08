# Configuration

All configuration files for Toast reside in `config/toast-api/`. They
contain text in Ruby syntax. The file naming is
arbitrary. Configurations can be placed into one file, or spread over
multiple files. All `*.rb` files in `config/toast-api` are processed on
application load.

Configurations files contain `expose(Model) {...}` stanzas, that
declare how a model is to be exposed via the HTTP+JSON interface.

The expose stanzas can contain following model/resource specific
configurations:

* exposing model attributes: lists for readable and writable attributes
* exposing model associations by URIs
* HTTP requests like GET, PATCH, POST, DELETE, LINK, UNLINK for associated models
* exposing class methods and scopes of models returning collections of model instances
* authorization for all requests
* custom handler definitions

Global settings and defaults are configured in
the [global configuration](global_config) file `config/toast-api.rb`.

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

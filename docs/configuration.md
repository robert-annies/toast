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

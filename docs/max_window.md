---
layout: page
title: Directive 'max_window'
---

`max_window {SIZE}`

Responses containing arrays of resources are delivered partially (a.k.a paging): for details see [Windowing](windowing).

The maximum window size is configured in
the [global configuration file](global_config), but can be overridden by this
directive individually. 
`SIZE` must be a positive integer or the symbol `:unlimited`, which will switch off limiting the number of records sent. Beware that this setting may lead to performance issues on large sets. 

`max_window` may appear under following directives:

* [`association`](association), when plural
* [`collection`](collection)


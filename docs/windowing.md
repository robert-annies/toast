---
layout: page
title: Windowing (Pagination)
---

Responses containing arrays of resources are delivered partially (a.k.a paging).
The HTTP headers _Range_ (request) and _Content-Range_ (response) are uitilized for windowing.

`Range: items={FROM}-{TO}`,

where `{FROM}` is the position of the first and `{TO}` of the last item
requested. Counting starts at 0. `{TO}` is optional, indicating a request from
`{FROM}` to the last item.

The response of a windowed collection/association contains a _Content-Range_ header:

`Content-Range: items={FROM}-{TO}/{SIZE}`,

where `{FROM}` and `{TO}` are defined as above, except that both are always
present. `{SIZE}` indicates the total number of items.

Windowing is applied to the relation or scope that is to be executed after
any custom [`handler`](handler) was applied. E.g. if a custom handler filters
the results by adding *where* or *order*-clauses the window is applied together with
the filter and/or ordering.

All collections and plural associations have a maximum window size defined in the [global configuration file](global_config) using the [`max_window` directive](max_window), which defaults to 42 if missing. 
It is possible to define the maximum window size for each collection/association indivdually using the same directive in the collection/association configuration. 
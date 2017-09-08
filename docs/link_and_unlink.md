# HTTP Methods LINK and UNLINK

Toast uses the HTTP methods LINK and UNLINK for associating and dis-associating existing resources.

LINK and UNLINK requests and semantics are not yet official. The implementation in Toast is based on the Internet-Draft [HTTP Link and Unlink Methods](https://datatracker.ietf.org/doc/draft-snell-link-method/). Therefore LINK/UNLINK may not be supported this way by proxies, web servers, middle boxes, client libraries, etc. 

To use LINK and UNLINK is unproblematic when using HTTPS, which is anyway recommended, since then requests are encrypted and inbetween-hops cannot see them.

In case it is not possbile to establish end-to-end TLS or a client library can use GET, PATCH, POST and DELETE only, Toast can be switched to use POST instead LINK and UNLINK transparently in the global configuration at `config/toast.yml` (see [Global Configuration File](global_config)).

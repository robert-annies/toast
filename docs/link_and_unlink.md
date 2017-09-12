# HTTP Methods LINK and UNLINK

Toast uses the HTTP methods LINK and UNLINK for associating and dis-associating existing resources.

Allthough the request methods LINK and UNLINK are mentioned in [RFC 2068, section 19.6.1.2f](https://tools.ietf.org/html/rfc2068#section-19.6.1.2) as "Addditional Request Methods" (alongside PATCH) they did not make it to be officially specified as part of HTTP 1.1. An Internet-Draft [HTTP Link and Unlink Methods](https://datatracker.ietf.org/doc/draft-snell-link-method/) exists, but it seems it is not being pushed forward. That's a pitty, because like PATCH, they fill a semantic gap in the protocol. 

Toast is based on the above Internet-Draft. Therefore LINK/UNLINK may not be supported by some proxies, web servers, middle boxes or client libraries. 

To use of LINK and UNLINK is unproblematic via HTTPS (which hides the request method from intermediate hops), if client and web server support them. 

In case it is not possbile to establish end-to-end TLS or a client library cannot send LINK/UNLINK Toast can be switched to use POST instead transparently in the global configuration at `config/toast.yml` (see [Global Configuration File](global_config)).

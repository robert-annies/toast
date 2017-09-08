---
layout: page
title: Response Codes		
---

There are a plenty of HTTP stastus codes available (see section 6 of [RFC&nbsp;7231](https://tools.ietf.org/html/rfc7231)). To select the right one for each event in Toast following approach was taken: Use the most general code availalbe on to minimize the number of possible response codes. It is hopeless to assume that the most specific code would help a API consumer application. There would be still a lot of amiguities depending on the business logic of the server application.

Toast only responds with:

* 200 OK: when there is was no problem handling the request. The response may have a payload or not. 
* 401 Unauthorized: the `allow` block defined for the respective request did not return _true_. 
* 404 Not Found: if the requested resource was not found or a target resource could not be found in LINK and UNLINK requests.
* 500 Internal Server Error: An unhandled exception was raised.

Additionally Toast logs any faulty response with an explanation why and also sets the custom HTTP head X-Toast-Error-Reason in order to convey the source of the problem from Toast's point of view.

It is also possibleto set the explaination from the business logig point of view by raising the exception `Toast::Error.new(message)`, ...

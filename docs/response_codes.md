---
layout: page
title: Response Codes		
---

Toast responds with following status codes:

* _200 OK_: when there is was no problem handling the request. The response may have a payload or not. 
* _401 Unauthorized_: the [`allow`](allow) block defined for the respective request did not return _true_. 
* _404 Not Found_: if the requested resource was not found or a target resource could not be found in LINK and UNLINK requests.
* _500 Internal Server Error_: An un-rescued exception was raised.

Additionally Toast logs any faulty response with an explanation and - in _development_ mode - sets the custom HTTP header X-Toast-Error-Reason in order to convey the source of the problem from Toast's point of view to the client. 

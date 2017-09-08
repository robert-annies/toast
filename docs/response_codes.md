# Response Codes		

Toast responds with following status codes:

* _200 OK_: when there is was no problem handling the request. The response may have a payload or not. 
* _201 Created_: when a record was created due to a POST request.
* _401 Unauthorized_: the [`allow`](allow) block defined for the respective request did not return _true_. 
* _404 Not Found_: if the requested resource was not found or a target resource could not be found in LINK and UNLINK requests.
* _500 Internal Server Error_: An un-rescued exception was raised.

Additionally Toast logs any faulty response with an explanation.
# Error Handling

Every error Toast encounters is captured and translated to a error response code, the reason is logged to `log/toast.log` and put into the response body (in development and test mode),

### 400 Bad Request

In handlers it is possible to call the method `bad_request(message)`, which will cause this response code. This can be used to check custom error conditions and fail the request. 

### 401 Unauthorized

The authentication hook in the global configuration returned _false_ or _nil_. 

The authorization hook of the requested endpoint returned _false_ or _nil_.

### 404 Not Found

The endpoint URI does not match any configured endpoint. 

A model instance with given ID could not be found.

### 405 Method Not Allowed

A request method is not supported for the requested resource. That means there was no `via-*` configuration found for the requested endpoint.  

### 409 Conflict

A handler of a PATCH or POST request returned `false`  due to validation errors. If any error were added to the model's `errors` list, the messages will be logged and included in the body (in development and test mode).

### 500 Internal Server Error

Any exception raised in `allow`-blocks and custom and default handlers will cause this response. The message is logged and embedded in the response body (development and test mode).




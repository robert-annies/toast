# Attribute Selection per Request

Toast interprets an special optional URI-parameter `toast_select` on GET requests. This parameter should contain a comma separated list of resource properties (model attributes). 
If given the representer will put attributes listed only into the response. This includes attributes, associations and _self_. 

For example when fetching large collection the client can reduce the representation to a small subset of what is actually needed. This can improve perfomance significantly, since there is less to render and transmit or certain expensive attributes can be omitted when not needed.



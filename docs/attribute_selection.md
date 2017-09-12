# Attribute Selection per Request

Toast interprets an special optional URI-parameter `toast_select` on GET requests. This parameter should contain a comma separated list of resource properties (model attributes). 
If given the representer will put attributes listed only into the response. This includes attributes, associations and _self_. 

For example when fetching large collection the client can reduce the representation to a small subset of what is actually needed. This can improve perfomance significantly, since there is less to render and transmit or certain expensive attributes can be omitted when not needed.

## Example

Without attribute selection all attributes are rendered:

{% highlight ruby %}
expose(Person) {
  readables :first_name, :last_name, :biography

  via_get {
    allow do |*args|
      true
    end
  }

  collection(:all) {
    via_get {
      allow do |*args|
        true
      end  
    }
  }
}
{% endhighlight %}

Request:

`GET https://example.com/people/44`

Response:
{% highlight json %}
{
    "self"      : "https://example.com/people/44",
    "first_name": "John",
    "last_name" : "Silver",
    "biography" : "Tempor aliqua cupidatat dolor in occaecat proident
          duis duis irure in dolor in magna ea aute magna aliquip incididunt
          incididunt excepteur laboris in fugiat qui culpa reprehenderit ea
          tempor laborum in fugiat ad dolore in qui veniam duis cillum sed
          laboris dolore ea in fugiat ut esse dolore pariatur in dolore nulla eu
          in tempor commodo est sint tempor ex sunt esse velit exercitation
          reprehenderit laboris aute incididunt ut mollit occaecat nulla aliqua
          commodo anim labore irure proident adipisicing excepteur fugiat
          eiusmod ut sed aliqua culpa et tempor anim nisi laboris et eu est
          nostrud id in dolor sunt anim est laborum sed id dolore ut ea in et." 
} 
{% endhighlight %}

When fetching a list of _People_ all the long texts can be omitted:

Request:

`GET https://www.example.com/people?toast_select=self,first_name,last_name`

Response:
{% highlight json %}
[{
    "self"      : "https://example.com/people/44",
    "first_name": "John",
    "last_name" : "Silver"
},{
    "self"      : "https://example.com/people/45",
    "first_name": "Billy",
    "last_name" : "Bones" 
},...]
{% endhighlight %}




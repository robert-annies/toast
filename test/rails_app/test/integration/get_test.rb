require 'test_helper'


# Test Cases Overview
=begin
|     |                                        | status | comment |
|-----+----------------------------------------+--------+---------|
| GET | single record by ID success            | ok     |         |
|     | single record ID not found             | ok     |         |
|     | single record instance by class method | ok     |         |
|     | default root collection success        | ok     |         |
|     | other root collection (a scope)        | ok     |         |
|     | collection with params                 | ok     |         |
|     | subresource: association collection    | ok     |         |
|     | subresource: attribute                 | ok     |         |

=end

class ToastTest < ActionDispatch::IntegrationTest

  include ModelFactory

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end

  # Replace this with your real tests.
  context "GET requests for single resources" do
    should "respond successfully on existing records" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      b1 = Banana.create :number => 895, :name => "tommie.rohan@kub.name"

      get "apples/#{a1.id}"
      assert_response :ok
      assert_equal({
                     "self" => "http://www.example.com/apples/#{a1.id}",
                     "number" => 45,
                     "bananas" => "http://www.example.com/apples/#{a1.id}/bananas",
                     "bananas:query"=>"http://www.example.com/apples/#{a1.id}/bananas/query",
                     "bananas:less_than_100"=> "http://www.example.com/apples/#{a1.id}/bananas/less_than_100",
                     "name" => "loyce.donnelly@daugherty.info"
                   }, json_response)

      get "bananas/#{b1.id}", nil, accept("application/banana-v1")
      assert_response :ok
      assert_equal({
                     "self" => "http://www.example.com/bananas/#{b1.id}",
                     "number" => 895,
                     "name" => "tommie.rohan@kub.name",
                     "curvature" => 8.18,
                     "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit" ,
                   }, json_response)
    end
    
    should "respond on class methods returning single instance" do
      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      
      get "apples/first", nil,  {'HTTP_ACCEPT'=>'application/apple+json'}
      assert_response :ok
      assert_equal({
                     "self" => "http://www.example.com/apples/#{a1.id}",
                     "number" => 45,
                     "bananas" => "http://www.example.com/apples/#{a1.id}/bananas",
                     "bananas:less_than_100"=> "http://www.example.com/apples/#{a1.id}/bananas/less_than_100",
                     "bananas:query"=>"http://www.example.com/apples/#{a1.id}/bananas/query",
                     "name" => "loyce.donnelly@daugherty.info"
                   }, json_response)

      
    end

    should "respond with '404 Not found' on non existing resources" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      b1 = Banana.create :number => 895, :name => "tommie.rohan@kub.name"
      d1 = Dragonfruit.create :number => 92, :name => "stephanie@wehner.info"

      # unknown id
      get "apples/9999"
      assert_response :not_found

      # unknown model 
      assert_raise ActionController::RoutingError do
        get "hamburgers/133"
      end

      # known model but not restful
      get "dragonfruits/92"
      assert_response :not_found

      # try to hack with exisiting class
      assert_raise ActionController::RoutingError do
        get "ActiveRecord%3A%3ABases/133"
      end

    end

    should "respond on collections" do
      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a3 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      a4 = Apple.create :number => 13, :name => "chadd.lind@abshire.com"

      get "apples"
      assert_response :ok
      assert_same_elements( [ { "number" => 45, "self" => "http://www.example.com/apples/#{a1.id}" },
                              { "number" => 133, "self" => "http://www.example.com/apples/#{a2.id}" },
                              { "number" => 465, "self" => "http://www.example.com/apples/#{a3.id}" },
                              { "number" => 13, "self" => "http://www.example.com/apples/#{a4.id}" }
                            ], json_response)

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      get "bananas/less_than_100", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_same_elements( [ { "number" => 45,
                                "name" => "loyce.donnelly@daugherty.info" ,
                                "curvature" => 8.18,
                                "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                                "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts" ,
                                "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit" ,
                                "self" => "http://www.example.com/bananas/#{b1.id}" },
                              { "number" => 13,
                                "name" => "chadd.lind@abshire.com",
                                "curvature" => 8.18,
                                "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                                "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts" ,
                                "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit" ,
                                "self" => "http://www.example.com/bananas/#{b4.id}" }
                            ], json_response)

    end
    
    should "respond on collections with params" do
      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      get "bananas/query?gt=100", nil, accept("application/bananas-v1")
      assert_response :ok
      
      assert_same_elements( [ { "number" => 133,
                                "name" => "camilla@leffler.ca" ,
                                "apple" =>       "http://www.example.com/bananas/#{b2.id}/apple",
                                "curvature" => 8.18,
                                "coconuts" =>    "http://www.example.com/bananas/#{b2.id}/coconuts" ,
                                "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit" ,
                                "self" =>         "http://www.example.com/bananas/#{b2.id}" },
                              { "number" => 465,
                                "name" => "ruth@balistreri.com",
                                "apple" =>       "http://www.example.com/bananas/#{b3.id}/apple",
                                "curvature" => 8.18,
                                "coconuts" =>    "http://www.example.com/bananas/#{b3.id}/coconuts" ,                                         
                                "dragonfruit" => "http://www.example.com/bananas/#{b3.id}/dragonfruit" ,
                                "self" =>         "http://www.example.com/bananas/#{b3.id}" }
                            ], json_response)    
    end

    should "respond on has_many associations" do

      c1 = Coconut.create :number => 831, :name => "bertram.schuster@stantonjacobs.com"
      c2 = Coconut.create :number => 9571, :name => "roscoe.daniel@kub.net"

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 145, :name => "theresa@deckowsipes.net", :coconuts => [c1,c2]
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a1.bananas = [b1, b3]

      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      a2.bananas = [b2, b4]
      

      get "apples/#{a1.id}/bananas", nil, accept("application/bananas-v1")
      assert_response :ok
      assert_equal [{"number" => 45,
                      "name" => "loyce.donnelly@daugherty.info",
                      "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                      "curvature" => 8.18,
                      "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b1.id}" },

                    {"number" => 465,
                      "name" => "ruth@balistreri.com",
                      "curvature" => 8.18,
                      "apple" =>  "http://www.example.com/bananas/#{b3.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b3.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b3.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b3.id}"}], json_response


      get "apples/#{a2.id}/bananas", nil, accept("application/bananas-v1")
      assert_response :ok
      assert_equal [{"number" => 145,
                      "name" => "theresa@deckowsipes.net",
                      "curvature" => 8.18,
                      "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b2.id}" },
                    {"number" => 13,
                      "curvature" => 8.18,
                      "name" => "chadd.lind@abshire.com",
                      "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b4.id}"}], json_response

    end
    
    should "respond with HTML on .html for single resources" do       
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"

      get "apples/#{a1.id}.html"      
      
      assert_response :ok
      assert_equal "text/html", @response.content_type

      assert_select "table>tr" do
        assert_select "td", 2
        assert_select "td", "camilla@leffler.ca"
        assert_select "td", "133"        
      end                        
    end

    should "respond with HTML on .html for resource collections" do       
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      
      get "apples.html"      
      
      assert_response :ok
      assert_equal "text/html", @response.content_type
      
      assert_select "ul" do
        assert_select "li", 2
        assert_select "li", "camilla@leffler.ca 133"
        assert_select "li", "ruth@balistreri.com 465"
      end                        
    end    
    
    should "respond with XML on .xml for single resources" do       
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      

      get "apples/#{a1.id}.xml"      

      assert_response :ok
      assert_equal "application/xml", @response.content_type

      assert_select "apple>name", "camilla@leffler.ca"
      assert_select "apple>number", "133"

    end    


    should "respond to assoications not maned like the class" do
      e1 = Eggplant.create({:number => 92, :name => "stephanie@wehner.info"}) do |eg|
        eg.potato = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info" 
        eg.dfruits = Dragonfruit.create!([{:number => 133, :name => "camilla@leffler.ca"},
                                           { :number => 465, :name => "ruth@balistreri.com"}])
      end  
        
      get "eggplants/#{e1.id}/dfruits"
      
      assert_response :ok
      assert_equal [{"self" => "http://www.example.com/dragonfruits/1"},
                    {"self" => "http://www.example.com/dragonfruits/2"}], json_response
      
      get "eggplants/#{e1.id}/potato"      
      assert_response :ok
      assert_equal({ "number" => 45, 
                     "self" => "http://www.example.com/apples/1",
                     "name" =>  "loyce.donnelly@daugherty.info",
                     "bananas"=>"http://www.example.com/apples/1/bananas",
                     "bananas:query"=>"http://www.example.com/apples/1/bananas/query",
                     "bananas:less_than_100"=> "http://www.example.com/apples/1/bananas/less_than_100"},
                   json_response)
      
    end

    should "respond to scoped associations" do
      
      b1=b2=b3=nil

      e1 = Eggplant.create({:number => 92, :name => "stephanie@wehner.info"}) do |eg|
        eg.bananas << (b1,b2,b3 = Banana.create!([{:number => 450, :name => "loyce.donnelly@daugherty.info"},
                                      {:number => 12, :name => "camilla@leffler.ca"},
                                      {:number => 45, :name => "ruth@balistreri.com"}]))
      end

      get "eggplants/first" 
      assert_response :ok
      assert_equal(
                   {"self"=>"http://www.example.com/eggplants/1",
                     "number"=>92,
                     "potato"=>"http://www.example.com/eggplants/1/potato",
                     "dfruits"=>"http://www.example.com/eggplants/1/dfruits",
                     "name"=>"stephanie@wehner.info",
                     "bananas"=>"http://www.example.com/eggplants/1/bananas",
                     "bananas:less_than_100" => "http://www.example.com/eggplants/1/bananas/less_than_100",
                     "bananas:query" => "http://www.example.com/eggplants/1/bananas/query" }, json_response)

      get "eggplants/#{e1.id}/bananas/less_than_100"
      assert_response :ok
      assert_equal [{"number" => 12,
                      "name" => "camilla@leffler.ca",
                      "curvature" => 8.18,
                      "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b2.id}" },
                    {"number" => 45,
                      "curvature" => 8.18,
                      "name" =>  "ruth@balistreri.com",
                      "apple" => "http://www.example.com/bananas/#{b3.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b3.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b3.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b3.id}"}], json_response
      
      get "eggplants/#{e1.id}/bananas/query?gt=40"
      assert_response :ok
      

      assert_equal [{"number" => 450,
                      "name" =>  "loyce.donnelly@daugherty.info",
                      "curvature" => 8.18,
                      "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b1.id}" },
                    {"number" => 45,
                      "curvature" => 8.18,
                      "name" =>  "ruth@balistreri.com",
                      "apple" => "http://www.example.com/bananas/#{b3.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b3.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b3.id}/dragonfruit",
                      "self" => "http://www.example.com/bananas/#{b3.id}"}], json_response

    end

    
  end # context GET
end

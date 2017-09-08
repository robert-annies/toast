require 'test_helper'
class GetTest < ActionDispatch::IntegrationTest

  def setup
    # clear all
    [Apple, Banana#, Coconut, Dragonfruit, Coconut, CoconutDragonfruit, Eggplant
    ].each {|m| m.delete_all}
  end

  context "Single resources" do
    should "be GET-able" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      b1 = Banana.create :number => 895, :name => "tommie.rohan@kub.name"

      get "/apples/#{a1.id}"
      assert_response :ok
      assert_equal({
                     "self" => "http://www.example.com/apples/#{a1.id}",
                     "number" => 45,
                     "bananas" => "http://www.example.com/apples/#{a1.id}/bananas",
                     "eggplants"=>"http://www.example.com/apples/#{a1.id}/eggplants",
                     "name" => "loyce.donnelly@daugherty.info"
                   }, json_response)

      get "/bananas/#{b1.id}", nil, accept("application/banana-v1")
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
=begin
    should "be GET-able as single finders with 'collections' directive" do
      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"

      get "/apples/first", nil,  {'HTTP_ACCEPT'=>'application/apple+json'}
      assert_response :ok
      assert_equal({
                     "self" => "http://www.example.com/apples/#{a1.id}",
                     "number" => 45,
                     "eggplants"=>"http://www.example.com/apples/#{a1.id}/eggplants",
                     "bananas" => "http://www.example.com/apples/#{a1.id}/bananas",
                     "name" => "loyce.donnelly@daugherty.info"
                   }, json_response)
    end

    should "be formatted by views according to the URI format suffix: .html" do
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"

      get "/apples/#{a1.id}.html"

      assert_response :ok
      assert_equal "text/html", @response.content_type

      assert_select "table>tr" do
        assert_select "td", 2
        assert_select "td", "camilla@leffler.ca"
        assert_select "td", "133"
      end
    end

    should "be formatted by views according to URI format suffix: .xml" do
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"


      get "/apples/#{a1.id}.xml"

      assert_response :ok
      assert_equal "application/xml", @response.content_type

      assert_select "apple>name", "camilla@leffler.ca"
      assert_select "apple>number", "133"

    end

    should "respond with serialized JSON objects and arrays" do
      c1 = Coconut.create!(:object => {'carrot'=>'red', 'apple'=> 'green'},
                           :array =>  [11,0.2, nil, "moon"])

      get "/fruits/coconuts/#{c1.id}"
      assert_response :ok
      assert_equal({"apple"=>"green", "carrot"=>"red"},  json_response['object'])
      assert_equal([11,0.2, nil, "moon"],  json_response['array'])

    end
  end

  context "Request for non-existing resources" do
    should "be responded with '404 Not found'" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      b1 = Banana.create :number => 895, :name => "tommie.rohan@kub.name"
      d1 = Dragonfruit.create :number => 92, :name => "stephanie@wehner.info"

      # unknown id
      get "/apples/9999"
      assert_response :not_found

      # unknown model
      assert_raise ActionController::RoutingError do
        get "/hamburgers/133"
      end

      # known model but not restful
      get "/dragonfruits/92"
      assert_response :not_found

      # try to hack with exisiting class
      assert_raise ActionController::RoutingError do
        get "/ActiveRecord%3A%3ABases/133"
      end
    end
  end # context non-existing

  context "Resource collections" do
    should "be GET-able" do
      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a3 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      a4 = Apple.create :number => 13, :name => "chadd.lind@abshire.com"

      get "/apples"
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

      get "/bananas/less_than_100", nil, accept("application/bananas-v1")
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

    should "be GET-able and process URI parameters with 'pass_params_to' directive" do
      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      get "/bananas/query?gt=100", nil, accept("application/bananas-v1")
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

    should "be formatted by views according to URI format suffix: .html" do
      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"

      get "/apples.html"

      assert_response :ok
      assert_equal "text/html", @response.content_type

      assert_select "ul" do
        assert_select "li", 2
        assert_select "li", "camilla@leffler.ca 133"
        assert_select "li", "ruth@balistreri.com 465"
      end
    end

    should "be paginated" do
      bananas = 48.times.each do |i|
        Banana.create :number => i
      end

      get "/bananas?page=1", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 10, json_response.length
      assert_equal (0..9).to_a, json_response.map{|x| x['number']}

      assert_equal '<http://www.example.com/bananas?page=2>; rel="next"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal '<http://www.example.com/bananas?page=5>; rel="last"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal '<http://www.example.com/bananas?page=1>; rel="first"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      get "/bananas?page=2", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 10, json_response.length
      assert_equal (10..19).to_a, json_response.map{|x| x['number']}

      assert_equal '<http://www.example.com/bananas?page=3>; rel="next"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal '<http://www.example.com/bananas?page=5>; rel="last"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal '<http://www.example.com/bananas?page=1>; rel="first"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal '<http://www.example.com/bananas?page=1>; rel="prev"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      get "/bananas?page=5", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 8, json_response.length
      assert_equal (40..47).to_a, json_response.map{|x| x['number']}

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal '<http://www.example.com/bananas?page=1>; rel="first"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal '<http://www.example.com/bananas?page=5>; rel="last"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal '<http://www.example.com/bananas?page=4>; rel="prev"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      # page past last one
      get "/bananas?page=80", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 0, json_response.length

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal '<http://www.example.com/bananas?page=1>; rel="first"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal '<http://www.example.com/bananas?page=5>; rel="last"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal '<http://www.example.com/bananas?page=5>; rel="prev"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}

      # query w/o matches
      get "/bananas/query?page=1&gt=9999"

      assert_equal 0, json_response.length

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal '<http://www.example.com/bananas/query?gt=9999&page=1>; rel="first"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal '<http://www.example.com/bananas/query?gt=9999&page=1>; rel="last"',
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      # no paging
      get "/bananas", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 48, json_response.length
      assert_equal nil, @response.header["Link"]

    end

  end # collections
  context "Collection associations" do
    should "be GET-able" do

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


      get "/apples/#{a1.id}/bananas", nil, accept("application/bananas-v1")
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


      get "/apples/#{a2.id}/bananas", nil, accept("application/bananas-v1")
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


    should "be GET-able when not named like the target class" do
      e1 = Eggplant.create({:number => 92, :name => "stephanie@wehner.info"}) do |eg|
        eg.potato = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
        eg.dfruits = Dragonfruit.create!([{:number => 133, :name => "camilla@leffler.ca"},
                                          {:number => 465, :name => "ruth@balistreri.com"}])
      end

      get "/eggplants/#{e1.id}/dfruits"

      assert_response :ok
      assert_equal [{"self" => "http://www.example.com/dragonfruits/1",
                      "banana"=>"http://www.example.com/dragonfruits/1/banana"},
                    {"self" => "http://www.example.com/dragonfruits/2",
                      "banana"=>"http://www.example.com/dragonfruits/2/banana"}], json_response

      get "/eggplants/#{e1.id}/potato"
      assert_response :ok
      assert_equal({ "number" => 45,
                     "self" => "http://www.example.com/apples/1",
                     "name" =>  "loyce.donnelly@daugherty.info",
                     "eggplants"=>"http://www.example.com/apples/1/eggplants",
                     "bananas"=>"http://www.example.com/apples/1/bananas"},
                   json_response)

    end

    should "be GET-able and process URI parameters with 'pass_params_to' directive" do

      a1 = Apple.create(:number => 133, :name => "camilla@leffler.ca") do |a|
        a.eggplants.build {|e| e.number = 23; e.name = "Travis Jakubowski"}
        a.eggplants.build {|e| e.number = 123; e.name = "Wanda Wilkinson"}
        a.eggplants.build {|e| e.number = 4000; e.name = "Fredy Wolf V"}
        a.eggplants.build {|e| e.number = 101; e.name = "Catharine Walter"}
      end

      $halt=true
      get "/apples/#{a1.id}/eggplants?greater_than=100"
      assert_response :ok
      assert_same_elements ["Wanda Wilkinson","Fredy Wolf V","Catharine Walter"], json_response.map{|x| x['name']}

    end

    should "be paginated" do

      apple = Apple.create

      48.times.each do |i|
        apple.bananas.create :number => i
      end

      get "/apples/#{apple.id}/bananas?page=1", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 15, json_response.length
      assert_equal (0..14).to_a, json_response.map{|x| x['number']}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=2>; rel=\"next\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=4>; rel=\"last\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=1>; rel=\"first\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}



      get "/apples/#{apple.id}/bananas?page=2", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 15, json_response.length
      assert_equal (15..29).to_a, json_response.map{|x| x['number']}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=3>; rel=\"next\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=4>; rel=\"last\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=1>; rel=\"first\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=1>; rel=\"prev\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      get "/apples/#{apple.id}/bananas?page=4&extra=foo", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 3, json_response.length
      assert_equal (45..47).to_a, json_response.map{|x| x['number']}

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?extra=foo&page=4>; rel=\"last\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?extra=foo&page=1>; rel=\"first\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}


      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?extra=foo&page=3>; rel=\"prev\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}


      # page past last one
      get "/apples/#{apple.id}/bananas?page=80", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 0, json_response.length

      assert_equal nil,
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="next"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=4>; rel=\"last\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="last"/}

      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=1>; rel=\"first\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="first"/}


      assert_equal "<http://www.example.com/apples/#{apple.id}/bananas?page=4>; rel=\"prev\"",
                   @response.header["Link"].split(', ').detect{|x| x =~ /rel="prev"/}

      # no paging
      get "/apples/#{apple.id}/bananas", nil, accept("application/bananas-v1")
      assert_response :ok

      assert_equal 48, json_response.length
      assert_equal nil, @response.header["Link"]

    end
=end
  end # context 'collection associations'
end

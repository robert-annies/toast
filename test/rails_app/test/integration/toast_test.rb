require 'test_helper'


# Test Cases Overview
=begin
|        |                                        | status | comment |
|--------+----------------------------------------+--------+---------|
| GET    | single resource success                | ok     |         |
|        | single resource not found              | ok     |         |
|        | default root collection success        | ok     |         |
|        | other root collection (a scope)        | ok     |         |
|        | subresource: association collection    | ok     |         |
|        | subresource: attribute                 | ok     |         |
|--------+----------------------------------------+--------+---------|
| POST   | post to root collection, success       | ok     |         |
|        | post with unexposed fields, failure    | ok     |         |
|        | post to association collection         | ok     |         |
|        | don't accept incorrect media type      | ?      |         |
|        | don't accept bad JSON                  | ?      |         |
|        |                                        |        |         |
|--------+----------------------------------------+--------+---------|
| PUT    | update single resource, success        | ok     |         |
|        | no partial updates                     | ok     |         |
|        | no creation                            | ok     |         |
|        | don't accept incorrect media type      | ok     |         |
|        | don't accept bad JSON                  | ok     |         |
|        | update subresource: attribute, success | ok     |         |
|--------+----------------------------------------+--------+---------|
| DELETE | single resoruce                        |        |         |
|        | not found                              |        |         |
|        |                                        |        |         |
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
                     "uri" => "http://www.example.com/apples/#{a1.id}",
                     "number" => 45,
                     "bananas" => "http://www.example.com/apples/#{a1.id}/bananas",
                     "name" => "loyce.donnelly@daugherty.info"
                   }, json_response)

      get "bananas/#{b1.id}"
      assert_response :ok
      assert_equal({
                     "uri" => "http://www.example.com/bananas/#{b1.id}",
                     "number" => 895,
                     "name" => "tommie.rohan@kub.name",
                     "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit" ,
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
      get "hamburgers/133"
      assert_response :not_found

      # known model but not restful
      get "dragonfruits/92"
      assert_response :not_found

      # try to hack with exisiting class
      get "ActiveRecord%3A%3ABases/133"
      assert_response :not_found

    end

    should "respond on collections" do
      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a3 = Apple.create :number => 465, :name => "ruth@balistreri.com"
      a4 = Apple.create :number => 13, :name => "chadd.lind@abshire.com"

      get "apples"
      assert_response :ok
      assert_same_elements( [ { "number" => 45, "uri" => "http://www.example.com/apples/#{a1.id}" },
                              { "number" => 133, "uri" => "http://www.example.com/apples/#{a2.id}" },
                              { "number" => 465, "uri" => "http://www.example.com/apples/#{a3.id}" },
                              { "number" => 13, "uri" => "http://www.example.com/apples/#{a4.id}" }
                            ], json_response)

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      get "bananas/find_some"
      assert_response :ok

      assert_same_elements( [ { "number" => 45,
                                "name" => "loyce.donnelly@daugherty.info" ,
                                "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                                "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts" ,
                                "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit" ,
                                "uri" => "http://www.example.com/bananas/#{b1.id}" },
                              { "number" => 13,
                                "name" => "chadd.lind@abshire.com",
                                "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                                "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts" ,
                                "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit" ,
                                "uri" => "http://www.example.com/bananas/#{b4.id}" }
                            ], json_response)

    end

    should "respond on subresources" do

      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com"

      get "apples/#{a1.id}/name"
      assert_response :ok
      assert_equal "camilla@leffler.ca", @response.body

      get "apples/#{a2.id}/number"
      assert_response :ok
      assert_equal "465", @response.body

      get "apples/#{a1.id}/xyz"
      assert_response :not_found


    end

    should "respond on has_many associations" do

      c1 = Coconut.create :number => 831, :name => "bertram.schuster@stantonjacobs.com"
      c2 = Coconut.create :number => 9571, :name => "roscoe.daniel@kub.net"

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b2 = Banana.create :number => 145, :name => "theresa@deckowsipes.net", :coconuts => [c1,c2]
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"

      a1 = Apple.create :number => 133, :name => "camilla@leffler.ca", :bananas => [b1, b3]
      a2 = Apple.create :number => 465, :name => "ruth@balistreri.com", :bananas => [b2, b4]

      get "apples/#{a1.id}/bananas"
      assert_response :ok
      assert_equal [{"number" => 45,
                      "name" => "loyce.donnelly@daugherty.info",
                      "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit",
                      "uri" => "http://www.example.com/bananas/#{b1.id}" },

                    {"number" => 465,
                      "name" => "ruth@balistreri.com",
                      "apple" =>  "http://www.example.com/bananas/#{b3.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b3.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b3.id}/dragonfruit",
                      "uri" => "http://www.example.com/bananas/#{b3.id}"}], json_response


      get "apples/#{a2.id}/bananas"
      assert_response :ok
      assert_equal [{"number" => 145,
                      "name" => "theresa@deckowsipes.net",
                      "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit",
                      "uri" => "http://www.example.com/bananas/#{b2.id}" },
                    {"number" => 13,
                      "name" => "chadd.lind@abshire.com",
                      "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                      "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts",
                      "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit",
                      "uri" => "http://www.example.com/bananas/#{b4.id}"}], json_response

    end

  end # context GET

  context "POST requests" do
    should "create resources" do

      record1 = {"number" => 3482, "name" => "Colton Kautzer"}
      record2 = {"number" => 3382, "name" => "Rickie Leffler"}

      post_json "fruits/coconuts", record1
      assert_response :created
      uri1 = @response.header["Location"]
      record1.merge! "uri" => uri1

      post_json "fruits/coconuts", record2
      assert_response :created
      uri2 = @response.header["Location"]
      record2.merge! "uri" => uri2

      get "fruits/coconuts"
      assert_same_elements [record1, record2], json_response

      get uri1
      assert_equal record1, json_response

      get uri2
      assert_equal record2, json_response
    end

    should "not set un-exposed fields" do

      record = {"number" => 3312, "name" => "Benny Hane I", "hidden" => "Cairo"}

      # try to post an un-exposed field
      post_json "fruits/coconuts", record
      assert_response :unprocessable_entity
    end

    should "create new associated records" do

      c1 = Coconut.create :number => 103, :name => "adaline@armstrong.com"
      c2 = Coconut.create :number => 906, :name => "genesis@jacobs.biz"

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info", :coconuts => [c1,c2]

      post_json "bananas/#{b1.id}/coconuts", {"number" => 123, "name" => "eriberto_morar@kochmraz.name"}
      assert_response :created

      assert_equal 123, json_response["number"]
      assert_equal "eriberto_morar@kochmraz.name", json_response["name"]

      c3 = Coconut.find_by_number 123
      assert_equal "http://www.example.com/coconuts/#{c3.id}", json_response["uri"]

      get "bananas/#{b1.id}/coconuts"
      assert_response :ok

      assert_same_elements [{"number" => 103, "name" => "adaline@armstrong.com", "uri" => "http://www.example.com/coconuts/#{c1.id}"},
                            {"number" => 906, "name" => "genesis@jacobs.biz", "uri" => "http://www.example.com/coconuts/#{c2.id}"},
                            {"number" => 123, "name" => "eriberto_morar@kochmraz.name", "uri" => "http://www.example.com/coconuts/#{c3.id}"}],
                           json_response
    end

    should "not accept bad JSON strings" do


      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"

      assert_raise StandardError do
        post "bananas/#{b1.id}/coconuts", "{\"number\" => 120, \"name => \"camilla@leffler.ca\"}",  {"CONTENT_TYPE"=> "application/json"}
      end

    end

  end # context POST requests

  context "PUT requests" do
    should "update resources" do

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"
      a1 = Apple.create :number => 245, :name => "heather@lockmankreiger.biz"

      put_json "bananas/#{b4.id}", {"name" => "linda@pacocha.name", "number" => 2211}
      assert_response :ok

      get "bananas/#{b4.id}"
      assert_equal({"number"=>2211,
                     "name"=> "linda@pacocha.name",
                     "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b4.id}"},
                   json_response)

      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_json, {"CONTENT_TYPE"=> "application/json+apple"}
      assert_response :ok

    end

    should "not do partial updates" do

      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"


      put_json "bananas/#{b2.id}", {"name" => "fatima@hills.name"}
      assert_response :unprocessable_entity

      get "bananas/#{b2.id}"
      assert_equal({"number"=>133,
                     "name"=>"camilla@leffler.ca",
                     "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b2.id}"}, json_response)

    end

    should "not create resources when id is not existing" do
      # discussable

      put_json "bananas/3420", {"name" => "linda@pacocha.name", "number" => 2211}
      assert_response :not_found

    end

    should "not accept wrong media types" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      a1 = Apple.create :number => 245, :name => "heather@lockmankreiger.biz"

      # x-www-form-url-encoded
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}
      assert_response :unsupported_media_type

      # xml
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml, {"CONTENT_TYPE"=> "application/xml"}
      assert_response :unsupported_media_type

      # should be application/apple+json
      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml, {"CONTENT_TYPE"=> "application/json"}
      assert_response :unsupported_media_type
    end

    should "not accept bad data" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"

      # corrupt json string
      #    can't assert any response here (what does Rails respond?)
      #    (assert_response :bad_request)
      assert_raise StandardError do
        put "bananas/#{b2.id}", "{\"number\" => 120, \"name => \"camilla@leffler.ca\"}",  {"CONTENT_TYPE"=> "application/json"}
      end

      # put Array
      put_json "bananas/#{b2.id}", ["foobar",42]
      assert_response :bad_request

    end

    should "update single attributes as subresources" do

      b1 = Banana.create :number => 133, :name => "mia_hartmann@carterbarton.net"
      b2 = Banana.create :number => 76, :name => "alan@king.net"

      put_json "bananas/#{b1.id}/number", 56
      assert_response :ok

      get "bananas/#{b1.id}"
      assert_equal({ "number" => 56,
                     "name" => "mia_hartmann@carterbarton.net",
                     "apple" => "http://www.example.com/bananas/#{b1.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b1.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b1.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b1.id}"},
                   json_response)

      put_json "bananas/#{b2.id}/name", "garrick_buckridge@quigley.org"
      assert_response :ok

      get "bananas/#{b2.id}"
      assert_equal({"number" => 76,
                     "name" => "garrick_buckridge@quigley.org",
                     "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b2.id}"}, json_response)

    end

  end
end

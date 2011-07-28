 require 'test_helper'


# Test Cases Overview
=begin
|     |                                        | status | comment |
|-----+----------------------------------------+--------+---------|
| PUT | update single resource, success        | ok     |         |
|     | no partial updates                     | ok     |         |
|     | no creation                            | ok     |         |
|     | don't accept incorrect media type      | ok     |         |
|     | don't accept bad JSON                  | ok     |         |
|     | update subresource: attribute, success | ok     |         |
=end

class ToastTest < ActionDispatch::IntegrationTest

  include ModelFactory

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end


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
      assert_response :forbidden

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

    should "not update when PUT is disallowed" do

      d1 = Dragonfruit.create :number => 35, :name => "mia_hartmann@carterbarton.net"

      put_json "dragonfruits/#{d1.id}", {:number => 24, :name => "mia_hartmann@carterbarton.net"}      
      assert_response :method_not_allowed
    end

  end
end

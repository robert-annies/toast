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
      a1.bananas << b3

      put_json "bananas/#{b4.id}", {"name" => "linda@pacocha.name", "number" => 2211, "curvature" => 0.12,
                                    "apple" => "nono" , "uri"=>"nono"}
      assert_response :ok

      get "bananas/#{b4.id}"
      assert_equal({"number"=>2211,
                     "name"=> "linda@pacocha.name",
                     "curvature" => 8.18,
                     "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b4.id}"},
                   json_response)

      put_json "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}, "application/json+apple"
      assert_response :ok

      a1.reload
    end

    should "partially update" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"

      put_json "bananas/#{b2.id}", {"name" => "fatima@hills.name"}
      assert_response :ok

      get "bananas/#{b2.id}"
      assert_equal({"number"=>133,
                     "name"=>"fatima@hills.name",
                     "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                     "curvature" => 8.18,
                     "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit" ,
                     "uri" => "http://www.example.com/bananas/#{b2.id}"}, json_response)

    end
    
    should "not update non-writable attributes" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      a1 = Apple.create :number => 43, :name => "dandre@ondricka.uk"
      b2.apple = a1
      b2.save

      put_json "bananas/#{b2.id}", {"name" => "fatima@hills.name", "apple_id" => 666}
      assert_response :ok
      
      b2.reload
      assert_equal a1.id, b2.apple_id

      get "bananas/#{b2.id}"
      assert_equal({"number"=>133,
                     "name"=>"fatima@hills.name",
                     "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                     "curvature" => 8.18,
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
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}, {"CONTENT_TYPE" => "application/x-www-form-urlencoded"}
      assert_response :unsupported_media_type

      # xml
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml, {"CONTENT_TYPE"=> "application/xml"}
      assert_response :unsupported_media_type

      # should be application/apple+json
      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_json, {"CONTENT_TYPE"=> "application/json"}
      assert_response :unsupported_media_type

      # payload is XML but content type is json+apple
      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml, {"CONTENT_TYPE"=> "application/json+apple"}
      assert_response :bad_request
      
           
      # payload is XML but content type is json 
      # 
      # This causes a decoding exception before ToastController can catch it, in Rails 3.1.x
      # put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml, {"CONTENT_TYPE" => "application/json"}
      # assert_response :bad_request
      
    end

    should "not accept bad data" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"

      # corrupt json string
      #    can't assert any response here (what does Rails respond?)
      #    (assert_response :bad_request)
      assert_raise StandardError do
        begin
          put "bananas/#{b2.id}", "{\"number\" => 120, \"name => \"camilla@leffler.ca\"}",  {"CONTENT_TYPE"=> "application/json"}
        rescue 
          raise StandardError  # different rails version raise different exceptions, equalize it
        end
      end

      # put Array
      put_json "bananas/#{b2.id}", ["foobar",42]
      assert_response :bad_request

    end

    should "not update when PUT is disallowed" do

      d1 = Dragonfruit.create :number => 35, :name => "mia_hartmann@carterbarton.net"

      put_json "dragonfruits/#{d1.id}", {:number => 24, :name => "mia_hartmann@carterbarton.net"}      
      assert_response :method_not_allowed
    end

  end
end

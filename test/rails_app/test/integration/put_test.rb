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

class PutTest < ActionDispatch::IntegrationTest

  include ModelFactory

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end


  context "PUT requests" do
    should "update resources" do

      c1 = Coconut.create!(:object => {'carrot'=>'red', 'apple'=> 'green'},
                           :array =>  [11,0.2, nil, "moon" ])

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b3 = Banana.create :number => 465, :name => "ruth@balistreri.com"
      b4 = Banana.create :number => 13, :name => "chadd.lind@abshire.com"
      a1 = Apple.create :number => 245, :name => "heather@lockmankreiger.biz"
      a1.bananas << b3

      put_json "bananas/#{b4.id}", {"name" => "linda@pacocha.name", "number" => 2211, "curvature" => 0.12,
                                    "apple" => "nono" , "self"=>"nono"},
               "application/banana-v2"

      assert_response :ok

      get "bananas/#{b4.id}",  nil, accept("application/banana-v1")
      assert_equal({"number"=>2211,
                     "name"=> "linda@pacocha.name",
                     "curvature" => 8.18,
                     "apple" => "http://www.example.com/bananas/#{b4.id}/apple",
                     "coconuts" => "http://www.example.com/bananas/#{b4.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b4.id}/dragonfruit" ,
                     "self" => "http://www.example.com/bananas/#{b4.id}"},
                   json_response)

      put_json "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}, "application/apple+json"
      assert_response :ok

      a1.reload

      put_json "fruits/coconuts/#{c1.id}", {:number => 3, :array => ['a',Time.utc(2000,"jan",1,20,15,1)]}, "application/json"
      assert_response :ok

      c1.reload
      assert_equal Time.utc(2000,"jan",1,20,15,1), c1.array.last

      # i wouldn't expect that Time object's rocket operator works with the ISO-time

    end

    should "partially update" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"

      put_json "bananas/#{b2.id}", {"name" => "fatima@hills.name"}, "application/banana-v1"
      assert_response :ok

      get "bananas/#{b2.id}"
      assert_equal({"number"=>133,
                     "name"=>"fatima@hills.name",
                     "apple" => "http://www.example.com/bananas/#{b2.id}/apple",
                     "curvature" => 8.18,
                     "coconuts" => "http://www.example.com/bananas/#{b2.id}/coconuts" ,
                     "dragonfruit" => "http://www.example.com/bananas/#{b2.id}/dragonfruit" ,
                     "self" => "http://www.example.com/bananas/#{b2.id}"}, json_response)

    end

    should "not update non-writable attributes" do
      b2 = Banana.create :number => 133, :name => "camilla@leffler.ca"
      a1 = Apple.create :number => 43, :name => "dandre@ondricka.uk"
      b2.apple = a1
      b2.save

      put_json "bananas/#{b2.id}", {"name" => "fatima@hills.name", "apple_id" => 666}, "application/banana-v1"
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
                     "self" => "http://www.example.com/bananas/#{b2.id}"}, json_response)
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
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"},  {"CONTENT_TYPE"=>"x-www-form-urlencoded"}
      assert_response :unsupported_media_type

      # xml
      put "bananas/#{b2.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml,   {"CONTENT_TYPE"=>"application/xml"}
      assert_response :unsupported_media_type

      # should be application/apple+json
      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_json,   {"CONTENT_TYPE"=>"application/json"}
      assert_response :unsupported_media_type

      # payload is XML but content type is json+apple
      put "apples/#{a1.id}", {:number => 120, :name => "camilla@leffler.ca"}.to_xml,  {"CONTENT_TYPE"=>"application/apple+json"}
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
      put_json "bananas/#{b2.id}", ["foobar",42], "application/banana-v1"
      assert_response :bad_request

    end

    should "add records to belongs_to associations" do

      b1 = Banana.create!
      b1.create_dragonfruit! {|d| d.number = 93} # to be replaced
      b1.save

      b2 = Banana.create!

      d1 = Dragonfruit.create! {|d| d.number = 39}

      put "/bananas/#{b1.id}/dragonfruit", nil, {"LINK" => "http://www.example.com/dragonfruits/#{d1.id}"}
      assert_response :no_content

      b1.reload
      assert_equal d1, b1.dragonfruit

      # type mismatch
      put "/bananas/#{b1.id}/dragonfruit", nil, {"LINK" => "http://www.example.com/bananas/#{b1.id}"}
      assert_response :not_acceptable

      # not found
      put "/bananas/#{b1.id}/dragonfruit", nil, {"LINK" => "http://www.example.com/dragonfruits/999"}
      assert_response :not_found

    end

    should "add records to has_one associations" do

      b2 = Banana.create!
      d1 = Dragonfruit.create! {|d| d.number = 39}

      put "/dragonfruits/#{d1.id}/banana", nil, {"LINK" => "http://www.example.com/bananas/#{b2.id}"}
      assert_response :no_content
      b2.reload
      assert_equal b2, d1.banana


      # type mismatch
      c1 = Coconut.create!
      put "/dragonfruits/#{d1.id}/banana", nil, {"LINK" => "http://www.example.com/coconuts/#{c1.id}"}
      assert_response :not_acceptable

      # not found
      put "/dragonfruits/#{d1.id}/banana", nil, {"LINK" => "http://www.example.com/bananas/999"}
      assert_response :not_found

    end


    should 'pass URI params to update_attibutes! if configured' do

      d1 = Dragonfruit.create! {|d| d.number = 39}

      put_json "/dragonfruits/#{d1.id}?write=true", {:number => 3}
      assert_response :ok
      assert_equal 3, d1.reload.number
    end

  end
end

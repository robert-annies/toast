require 'test_helper'


# Test Cases Overview
=begin
|        |                                        | status | comment |
|--------+----------------------------------------+--------+---------|
| POST   | post to root collection, success       | ok     |         |
|        | post with unexposed fields, failure    | ok     |         |
|        | post to association collection         | ok     |         |
|        | don't accept incorrect media type      | ?      |         |
|        | don't accept bad JSON                  | ?      |         |
|        |                                        |        |         |
=end

class ToastTest < ActionDispatch::IntegrationTest

  include ModelFactory

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end


  context "POST requests" do
    should "create resources" do

      record1 = {"number" => 3482, "name" => "Colton Kautzer"}
      record2 = {"number" => 3382, "name" => "Rickie Leffler"}

      post_json "fruits/coconuts", record1
      assert_response :created
      uri1 = @response.header["Location"]
      record1.merge! "uri" => uri1
      assert_equal record1, json_response

      post_json "fruits/coconuts", record2
      assert_response :created
      uri2 = @response.header["Location"]
      record2.merge! "uri" => uri2
      assert_equal record2, json_response

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
      assert_response :forbidden
    end

    should "create new associated records" do

      c1 = Coconut.create :number => 103, :name => "adaline@armstrong.com"
      c2 = Coconut.create :number => 906, :name => "genesis@jacobs.biz"

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info", :coconuts => [c1,c2]

      post_json "bananas/#{b1.id}/coconuts", {"number" => 123, "name" => "eriberto_morar@kochmraz.name"}
      assert_response :created

      assert_equal({"number" => 123, "name" => "eriberto_morar@kochmraz.name", "uri" => "http://www.example.com/coconuts/3"}, json_response)

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

    should "not create when POST is disallowed" do 
      post_json "dragonfruits",{"number" => 35, "name" => "mia_hartmann@carterbarton.net"}
      assert_response :method_not_allowed
    end


  end # context POST requests
end

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

    should "not set non-writable fields" do

      c0 = {"number" => 3312, "name" => "Benny Hane I", "hidden" => "Cairo"}
      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"

      # try to post a non-writable field to root collecton
      post_json "fruits/coconuts", c0
      assert_response :created

      c1 = Coconut.first
      assert_equal "Capetown", c1.hidden # "Capetown" is the default in the db-schema
      assert_equal 3312, c1.number
      assert_equal "Benny Hane I", c1.name 
      
    end

    should "not set non-writable fields in associate collection" do

      c0 = {"number" => 3312, "name" => "Benny Hane I", "hidden" => "Cairo"}
      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"

      # try to post a non-writable field to a association 
      post_json "bananas/#{b1.id}/coconuts", c0
      assert_response :created
      
      c2 = Coconut.last
      assert_equal "Capetown", c2.hidden # "Capetown" is the default in the db-schema
      assert_equal 3312, c2.number
      assert_equal "Benny Hane I", c2.name 
  
    end

    should "create new associated records" do

      c1 = Coconut.create :number => 103, :name => "adaline@armstrong.com"
      c2 = Coconut.create :number => 906, :name => "genesis@jacobs.biz"

      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      b1.coconuts = [c1,c2]

      post_json "bananas/#{b1.id}/coconuts", {"number" => 123, "name" => "eriberto_morar@kochmraz.name"}
      assert_response :created

      assert_equal({"number" => 123, "name" => "eriberto_morar@kochmraz.name", 
                     "uri" => "http://www.example.com/fruits/coconuts/3"}, json_response)

      c3 = Coconut.find_by_number 123
      assert_equal "http://www.example.com/fruits/coconuts/#{c3.id}", json_response["uri"]

      get "bananas/#{b1.id}/coconuts"
      assert_response :ok

      assert_same_elements [{"number" => 103, "name" => "adaline@armstrong.com", "uri" => "http://www.example.com/fruits/coconuts/#{c1.id}"},
                            {"number" => 906, "name" => "genesis@jacobs.biz", "uri" => "http://www.example.com/fruits/coconuts/#{c2.id}"},
                            {"number" => 123, "name" => "eriberto_morar@kochmraz.name", "uri" => "http://www.example.com/fruits/coconuts/#{c3.id}"}],
                           json_response
    end


    should "not accept bad JSON strings" do


      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"

      assert_raise StandardError do
        begin        
          post "bananas/#{b1.id}/coconuts", "{\"number\" => 120, \"name => \"camilla@leffler.ca\"}",  {"CONTENT_TYPE"=> "application/json"}
        rescue 
          raise StandardError  # diffirent rails version raise different exceptions, equalize it
        end
      end

    end

    should "not create when POST is disallowed" do 
      post_json "dragonfruits",{"number" => 35, "name" => "mia_hartmann@carterbarton.net"}
      assert_response :method_not_allowed
    end


  end # context POST requests
end

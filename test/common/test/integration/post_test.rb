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

class PostTest < ActionDispatch::IntegrationTest

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end


  context "POST requests" do
    should "create resources" do

      # different defaults for time precisions from Rails 4.1
      if Rails::VERSION::MAJOR >= 4 and Rails::VERSION::MINOR >= 1
        ActiveSupport::JSON::Encoding.time_precision = 0
      end

      record1 = {
        "number" => 3482, "name" => "Colton Kautzer",
        "array" => [0.2, 8, 'sun', nil, Time.utc(2000,"jan",1,20,15,1) ],
        "object" => {'carrot' => 'red', 'apple' => 'green'}
      }

      record2 = {
        "number" => 3382, "name" => "Rickie Leffler",
        "array" => [1,2,3], "object" => {}}

      post_json "/fruits/coconuts", record1
      assert_response :created
      uri1 = @response.header["Location"]

      record1.merge! "self" => uri1
      record1['array'][4] = Time.utc(2000,"jan",1,20,15,1).strftime("%Y-%m-%dT%H:%M:%SZ")

      assert_equal record1, json_response

      post_json "/fruits/coconuts", record2
      assert_response :created
      uri2 = @response.header["Location"]
      record2.merge! "self" => uri2
      assert_equal record2, json_response

      get "/fruits/coconuts"
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
      post_json "/fruits/coconuts", c0
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
      post_json "/bananas/#{b1.id}/coconuts", c0
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

      post_json "/bananas/#{b1.id}/coconuts", {"number" => 123, "name" => "eriberto_morar@kochmraz.name"}
      assert_response :created

      assert_equal({"number" => 123, "name" => "eriberto_morar@kochmraz.name",
                     "self" => "http://www.example.com/fruits/coconuts/3",
                     "array" => [], "object" => {}}, json_response)

      c3 = Coconut.find_by_number 123
      assert_equal "http://www.example.com/fruits/coconuts/#{c3.id}", json_response["self"]

      get "/bananas/#{b1.id}/coconuts"
      assert_response :ok

      assert_same_elements [{"number" => 103, "name" => "adaline@armstrong.com", "self" => "http://www.example.com/fruits/coconuts/#{c1.id}",
                              "array" => [], "object" => {}},
                            {"number" => 906, "name" => "genesis@jacobs.biz", "self" => "http://www.example.com/fruits/coconuts/#{c2.id}",
                              "array" => [], "object" => {}},
                            {"number" => 123, "name" => "eriberto_morar@kochmraz.name", "self" => "http://www.example.com/fruits/coconuts/#{c3.id}",
                              "array" => [], "object" => {}}],
                           json_response
    end


    should "not accept bad JSON strings" do


      b1 = Banana.create :number => 45, :name => "loyce.donnelly@daugherty.info"

      assert_raise StandardError do
        begin
          post "/bananas/#{b1.id}/coconuts", "{\"number\" => 120, \"name => \"camilla@leffler.ca\"}",  {"CONTENT_TYPE"=> "application/json"}
        rescue
          raise StandardError  # diffirent rails version raise different exceptions, equalize it
        end
      end

    end

    should "not create when POST is not allowed" do
      post_json "/dragonfruits",{"number" => 35, "name" => "mia_hartmann@carterbarton.net"}
      assert_response :method_not_allowed
    end


    should "add records to has_many associations" do
      b1=nil; b2=nil; e1=nil; e2=nil

      a1 = Apple.create do |a|
        a.bananas << (b1 = Banana.create!)
        a.bananas << (b2 = Banana.create!)
      end

      b3 = Banana.create!

      post "/apples/#{a1.id}/bananas", nil, {"LINK" => "http://www.example.com/bananas/#{b3.id}"}
      assert_response :no_content

      a1.reload
      assert_same_elements [b1, b2, b3], a1.bananas

      # type mismatch
      c1 = Coconut.create!
      post "/apples/#{a1.id}/bananas", nil, {"LINK" => "http://www.example.com/coconuts/#{c1.id}"}
      assert_response :not_acceptable

      # not found
      post "/apples/#{a1.id}/bananas", nil, {"LINK" => "http://www.example.com/babanas/999"}
      assert_response :not_found

    end

    should "add records to hbtm associations" do
      e1=nil; e2=nil

      a2 = Apple.create do |a|
        a.eggplants << (e1 = Eggplant.create!)
        a.eggplants << (e2 = Eggplant.create!)
      end

      e3 = Eggplant.create!
      a3 = Apple.create!
      a4 = Apple.create!

      post "/apples/#{a2.id}/eggplants", nil, {"LINK" => "http://www.example.com/eggplants/#{e3.id}"}
      assert_response :no_content
      post "/eggplants/#{e3.id}/apples", nil, {"LINK" => "http://www.example.com/apples/#{a3.id}"}
      assert_response :no_content
      post "/eggplants/#{e3.id}/apples", nil, {"LINK" => "http://www.example.com/apples/#{a4.id}"}
      assert_response :no_content

      a2.reload; e3.reload
      assert_same_elements [e1, e2, e3], a2.eggplants
      assert_same_elements [a2, a3, a4], e3.apples

      # type mismatch
      c1 = Coconut.create!
      post "/apples/#{a2.id}/eggplants", nil, {"LINK" => "http://www.example.com/coconuts/#{c1.id}"}
      assert_response :not_acceptable

      # not found
      post "/apples/#{a2.id}/eggplants", nil, {"LINK" => "http://www.example.com/eggplants/999"}
      assert_response :not_found

    end
  end # context POST requests
end

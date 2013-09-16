require 'test_helper'


# Test Cases Overview
=begin
|--------+----------------------------------------+--------+---------|
| DELETE | single resoruce                        |        |         |
|        | not found                              |        |         |
|        |                                        |        |         |
=end

class DeleteTest < ActionDispatch::IntegrationTest

  def setup
    # clear all
    [Apple, Banana, Coconut, Dragonfruit, Coconut, CoconutDragonfruit].each {|m| m.delete_all}
  end

  context "DELETE requests" do
    should "delete records" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a3 = Apple.create :number => 123, :name => "roy@hobgard.co"
l

      delete "apples/#{a1.id}"
      assert_response :no_content

      get "apples"
      assert_same_elements [{"number" => 133, "self" => "http://www.example.com/apples/#{a2.id}"},
                            {"number" => 123, "self" => "http://www.example.com/apples/#{a3.id}"}],
                           json_response


      delete "apples/#{a3.id}"
      assert_response :no_content


      get "apples"

      assert_equal([{"number" => 133, "self" => "http://www.example.com/apples/#{a2.id}"}],
                   json_response)


    end

    should "not deleted records if not permitted" do

      d1 = Dragonfruit.create :number => 35, :name => "mia_hartmann@carterbarton.net"

      delete "dragonfruits/#{d1.id}"
      assert_response :method_not_allowed

    end

    should "remove records from has_many associations" do

      b1 = nil; b2 = nil; b3 = nil; b4 = nil;

      a1 = Apple.create do |a|
        a.bananas << (b1 = Banana.create!)
        a.bananas << (b2 = Banana.create!)
        a.bananas << (b3 = Banana.create!)
        a.bananas << (b4 = Banana.create!)
      end

      delete "/apples/#{a1.id}/bananas",nil, {"LINK" => "http://www.example.com/bananas/#{b1.id}"}
      assert_response :no_content
      delete "/apples/#{a1.id}/bananas",nil, {"LINK" => "http://www.example.com/bananas/#{b3.id}"}
      assert_response :no_content

      a1.reload
      assert_same_elements [b1,b2,b3,b4], Banana.all
      assert_same_elements [b2,b4], a1.bananas

      # not linked anymore (DELETE is idempotent)
      delete "/apples/#{a1.id}/bananas",nil, {"LINK" => "http://www.example.com/bananas/#{b3.id}"}
      assert_response :no_content
      a1.reload
      assert_same_elements [b2,b4], a1.bananas

    end

    should "remove records from hbtm associations" do
     e1=nil;e2=nil;e3=nil;e4=nil

      a1 = Apple.create do |a|
        a.eggplants << (e1 = Eggplant.create!)
        a.eggplants << (e2 = Eggplant.create!)
        a.eggplants << (e3 = Eggplant.create!)
        a.eggplants << (e4 = Eggplant.create!)
      end

      e3.apples << (a2 = Apple.create)
      e3.apples << (a3 = Apple.create)
      e3.apples << (a4 = Apple.create)

      delete "/apples/#{a1.id}/eggplants",nil, {"LINK" => "http://www.example.com/eggplants/#{e1.id}"}
      assert_response :no_content
      delete "/apples/#{a1.id}/eggplants",nil, {"LINK" => "http://www.example.com/eggplants/#{e3.id}"}
      assert_response :no_content

      a1.reload
      e1.reload
      e3.reload

      assert_same_elements [e2,e4],    a1.eggplants
      assert_same_elements [],         e1.apples
      assert_same_elements [a2,a3,a4], e3.apples

      # not linked anymore (DELETE is idempotent)
      delete "/apples/#{a1.id}/eggplants",nil, {"LINK" => "http://www.example.com/eggplants/#{e3.id}"}
      assert_response :no_content
      a1.reload
      assert_same_elements [e2,e4],    a1.eggplants
    end

    should "remove records from belongs_to associations" do
      d1 = Dragonfruit.create!
      b1 = Banana.create! {|b| b.dragonfruit = d1}

      delete "/bananas/#{b1.id}/dragonfruit", nil, {"LINK" => "http://www.example.com/dragonfruits/#{d1.id}"}
      assert_response :no_content

      b1.reload
      assert_equal nil, b1.dragonfruit

      # not linked anymore (DELETE is idempotent)
      delete "/bananas/#{b1.id}/dragonfruit", nil, {"LINK" => "http://www.example.com/dragonfruits/#{d1.id}"}
      assert_response :no_content

      b1.reload
      assert_equal nil, b1.dragonfruit

    end

    should "remove records from has_one associations" do
      d1 = Dragonfruit.create!
      b1 = Banana.create! {|b| b.dragonfruit = d1}

      delete "/dragonfruits/#{d1.id}/banana", nil, {"LINK" => "http://www.example.com/bananas/#{b1.id}"}
      assert_response :no_content

      d1.reload
      assert_equal nil, d1.banana

      # not linked anymore (DELETE is idempotent)
      delete "/dragonfruits/#{d1.id}/banana", nil, {"LINK" => "http://www.example.com/bananas/#{b1.id}"}
      assert_response :no_content

      d1.reload
      assert_equal nil, d1.banana
    end
  end
end

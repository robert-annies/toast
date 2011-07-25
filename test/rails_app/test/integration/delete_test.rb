require 'test_helper'


# Test Cases Overview
=begin
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

  context "resources" do
    should "be deletable" do

      a1 = Apple.create :number => 45, :name => "loyce.donnelly@daugherty.info"
      a2 = Apple.create :number => 133, :name => "camilla@leffler.ca"
      a3 = Apple.create :number => 123, :name => "roy@hobgard.co"
          
      
      delete "apples/#{a1.id}"
      assert_response :ok

      get "apples"
      assert_same_elements [{"number" => 133, "uri" => "http://www.example.com/apples/#{a2.id}"},
                            {"number" => 123, "uri" => "http://www.example.com/apples/#{a3.id}"}],
                           json_response
  

      delete "apples/#{a3.id}"
      assert_response :ok


      get "apples"

      assert_equal([{"number" => 133, "uri" => "http://www.example.com/apples/#{a2.id}"}],
                   json_response) 
      

    end
    
    should "not be deleted when DELETE is disallowed" do
      
      d1 = Dragonfruit.create :number => 35, :name => "mia_hartmann@carterbarton.net"

      delete "dragonfruits/#{d1.id}"
      assert_response :method_not_allowed
      
    end
  end
end

require 'test_helper'
class MiscTest < ActionDispatch::IntegrationTest

  context "Toast" do
    should "provide JSON representation of configured model class" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apple = Apple.create!(:name => 'Joe', :number => 917)
      apple.bananas.create!(:name => 'Bianca', :number => 9540)

      assert_equal({ 'self'    => "http://www.example.com/apples/#{apple.id}",
                     'all'     => "http://www.example.com/apples",
                     'first'   => "http://www.example.com/apples/first",
                     'bananas' => "http://www.example.com/apples/#{apple.id}/bananas",
                     'bananas_surprise' => "http://www.example.com/apples/#{apple.id}/bananas_surprise",
                     'kind'    => "tree fruit",
                     'name'    => "Joe",
                     'number'  => 917 },
                   Toast.represent(apple, 'http://www.example.com'))

    end
  end
end

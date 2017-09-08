require 'test_helper'
class RouteTest < ActionDispatch::IntegrationTest

  context "non-Toast routes" do
    should "should be served" do
      Toast.init 'test/files/toast_config_default_handlers/*'
      get "/tomato"
      assert_response :ok
      assert_equal "A Tomato", @response.body
    end
  end
end

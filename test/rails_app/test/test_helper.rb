ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'factory'
require 'shoulda'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def json_response
    ActiveSupport::JSON.decode(@response.body)
  end
  
  def post_json uri, payload, media=nil
    post uri, payload.to_json, (media.nil? ? {"CONTENT_TYPE"=>"application/json"} :  {"CONTENT_TYPE"=> media})
  end

  def put_json uri, payload, media=nil
    put uri, payload.to_json, (media.nil? ? {"CONTENT_TYPE"=>"application/json"} :  {"CONTENT_TYPE"=> media} )
  end

end

# Patch bug in ruby 1.9.2-p180
if RUBY_VERSION == "1.9.2" and RUBY_PATCHLEVEL <= 180
  module MiniTest::Assertions
    def assert_block msg = nil
      assert yield, (msg ? msg : "Expected block to return true value.")
    end
  end
end

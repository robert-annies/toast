require 'test_helper'
class AuthenticationTest < ActionDispatch::IntegrationTest

  context 'authentication hook (global settings)' do
    should 'verify the requests credentials (basic auth)' do

      Toast.init 'test/files/get_canonical_auth.rb', 'test/files/settings-basic-auth.rb'
      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json",
                    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials('john','wrong')},
          xhr: true

      assert_response :unauthorized

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json",
                    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials('john','abc')},
          xhr: true

      assert_response :ok

    end
  end
end

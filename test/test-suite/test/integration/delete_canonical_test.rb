require 'test_helper'
class DeleteCanonicalTest < ActionDispatch::IntegrationTest
  context 'DELETE requests to canonical-URIs' do
    should 'remove the object'  do
      #
      # success tests
      #
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      delete "/apples/#{apples.third.id}",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :no_content
      assert_equal [952,1092], Apple.all.map{|a| a.number}

      #
      # failure tests
      #

      # not found
      delete "/apples/999",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :not_found
      assert_equal "Couldn't find Apple with 'id'=999", @response.body

      # DELETE not defined
      banana = Banana.create
      delete "/bananas/#{banana.id}",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :method_not_allowed
      assert_equal 'GET', @response.headers['Allow']

      # unauthorized by allow block
      delete "/apples/#{apples.second.id}",
             headers:  mkhd(token: 'TOK_user'),
             xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:18",
                   @response.body
      # unknown token
      delete "/apples/#{apples.second.id}",
             headers:  mkhd(token: 'TOK_unknown'),
             xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # resource not exposed
      delete "/oranges/123",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :not_found
      assert_equal "no API configuration found for endpoint /oranges/123", @response.body

      # aborted by callback
      delete "/apples/#{apples.second.id}",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :conflict
      assert_equal "deletion of Apple#2 aborted: before_destroy callback threw :abort", @response.body

    end
  end

  context 'DELETE requests to canonical-URIs with parameters' do
    should 'remove the object'  do
      #
      # success tests
      #
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      delete "/apples/#{apples.third.id}?log",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :no_content
      assert_equal [952,1092], Apple.all.map{|a| a.number}
      assert_not_nil `tail log/test.log` =~ /Apple.* was deleted$/


      # allow block raises exception
      delete "/apples/#{apples.first.id}?allow_bomb",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:46",
                   @response.body

      # handler raises exception
      delete "/apples/#{apples.first.id}?handler_bomb",
             headers:  mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in handler: `Boom!' in test/files/parameterized_requests/apple.rb:52",
                   @response.body

    end
  end
end

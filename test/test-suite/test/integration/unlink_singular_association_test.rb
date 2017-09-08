require 'test_helper'
class UnlinkSingularAssociationTest < ActionDispatch::IntegrationTest
  context 'UNLINK requests to singular-association-URIs' do
    should 'remove association of source and target object'  do
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette', apple: apples.first)

      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.first.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :ok
      assert_nil banana.reload.apple


      #
      # failure tests
      #

      banana.apple = apples.second
      banana.save

      # association not defined at all
      unlink "/bananas/#{banana.id}/apple_unknown",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "association `Banana#apple_unknown' not configured", @response.body

      # unknown token
      unlink "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_unknown')),
           xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body


      # unauthorized by allow block
      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_user')),
             xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/banana.rb:42",
                   @response.body



      # UNLINK not configured
      unlink "/bananas/#{banana.id}/apple_surprise",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :method_not_allowed
      assert_equal "GET", @response.headers['Allow']
      assert_equal "UNLINK not configured", @response.body

      # source not found
      unlink "/bananas/9999/apple",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "Banana#9999 not found", @response.body

      # target not found
      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "<http://wwww.example.com/apples/9999>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "Apple#9999 not found", @response.body

      # target class invalid
      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{banana.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :bad_request
      assert_equal "target class `Banana' invalid, expect: `Apple'", @response.body

      # target not associated
      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.first.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :conflict
      assert_equal "target `Apple#2' is not associated, cannot unlink `Apple#1'",
                   @response.body

      # Link header missing
      unlink "/bananas/#{banana.id}/apple",
             headers: mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # Link header invalid
      unlink "/bananas/#{banana.id}/apple",
             headers: {"Link" => "http://wwww.example.com/apples/#{apples.second.id}; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body
    end
  end
  context 'UNLINK requests to singular-association-URIs with URI params'  do
    ###
    # parameterized request
    ###
    should "remove association of source and target object" do
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette', apple: apples.first)

      unlink "/bananas/#{banana.id}/apple?doit=yes",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.first.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :ok
      assert_nil banana.reload.apple

      banana.apple = apples.second
      banana.save

      unlink "/bananas/#{banana.id}/apple?doit=no",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :ok
      assert_equal apples.second, banana.reload.apple

      #
      # failure tests
      #
      unlink "/bananas/#{banana.id}/apple?doit=maybe",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_unlink handler: `Say yes or no' in test/files/parameterized_requests/banana.rb:65",
                   @response.body


      # exception in allow block
      unlink "/bananas/#{banana.id}/apple?bomb_for_allow",
             headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
               merge(mkhd(token: 'TOK_user')),
             xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_unlink handler: `Boom!' in test/files/parameterized_requests/banana.rb:51",
                   @response.body
    end
  end
end

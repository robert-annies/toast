require 'test_helper'
class LinkSingularAssociationTest < ActionDispatch::IntegrationTest
  context 'LINK requests to singular-association-URIs' do
    should 'associate source with target object'  do
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette')

      # link with first apple
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.first.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal apples.first.id, banana.reload.apple.id

      # re-link with second
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal apples.second.id, banana.reload.apple.id

      #
      # failure tests
      #

      # association not defined at all
      link "/bananas/#{banana.id}/apple_unknown",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.third.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "association `Banana#apple_unknown' not configured", @response.body

      # unknown token
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.third.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_unknown')),
           xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # unauthorized by allow block
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.third.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_user')),
           xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/banana.rb:36",
                   @response.body

      # LINK not configured
      link "/bananas/#{banana.id}/apple_surprise",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.third.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :method_not_allowed
      assert_equal "GET", @response.headers['Allow']
      assert_equal "LINK not configured", @response.body

      # target not found
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/100000>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "Apple#100000 not found", @response.body

      # source not found
      link "/bananas/999999/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.third.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "Banana#999999 not found", @response.body

      # target class invalid
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :bad_request
      assert_equal "target class `Banana' invalid, expect: `Apple'", @response.body

      # Link header missing

      link "/bananas/#{banana.id}/apple",
           headers: mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # Link header invalid
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana.id}>; ref=\"unrelated\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body
    end
  end

  context 'LINK requests to singular-association-URIs with URI params'  do
    ###
    # parameterized request
    ###
    should "associate source with target object" do
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette')

      # link with first apple
      link "/bananas/#{banana.id}/apple",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.first.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal apples.first.id, banana.reload.apple.id

      # link with second (unless existing)
      link "/bananas/#{banana.id}/apple?keep_existing=true",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal apples.first.id, banana.reload.apple.id

      #
      # failure tests
      #

      # trigger exception in handler
      link "/bananas/#{banana.id}/apple?bomb",
           headers: {"Link" => "<http://wwww.example.com/apples/#{apples.second.id}>; ref=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception from via_link handler: Boom!", @response.body

    end
  end

end

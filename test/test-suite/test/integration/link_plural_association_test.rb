require 'test_helper'
class LinkPluralAssociationTest < ActionDispatch::IntegrationTest
  context 'LINK requests to plural-association-URIs' do
    should 'associate source with target object'  do

      #
      # success tests
      #

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette', apple: apples.first)
      banana2 = Banana.create!(name: 'Phasellus neque orci, porta a')

      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal ['Jeanette','Phasellus neque orci, porta a'], apples.first.bananas.map(&:name)

      apples.first.bananas.delete(banana2)

      #
      # failure tests
      #

      # association not defined at all
      link "/apples/#{apples.first.id}/bananas_unknown",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "association `Apple#bananas_unknown' not configured", @response.body

      # unknown token
      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_unknown')),
           xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # unauthorized by allow block
      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_user')),
           xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:58", @response.body

      # source not found
      link "/apples/999/bananas",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "Couldn't find Apple with 'id'=999", @response.body

      # target not found
      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http://wwww.example.com/bananas/888>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "Couldn't find Banana with 'id'=888", @response.body

      # LINK not defined
      link "/apples/#{apples.first.id}/bananas_surprise",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :method_not_allowed
      assert_equal "GET", @response.headers['Allow']
      assert_equal "LINK not configured", @response.body

      # Link header missing
      link "/apples/#{apples.first.id}/bananas",
           headers: mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # Link header invalid
      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http:wwww.example.com/bananas#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # target is not AR model
      link "/apples/#{apples.first.id}/bananas",
           headers: {"Link" => "<http://wwww.example.com/strings/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :not_found
      assert_equal "target class `String' is not an `ActiveRecord'", @response.body

    end
  end
  context 'LINK requests to plural-association-URIs wwith parameters' do
    should 'associate source with target object'  do

      #
      # success tests
      #

      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      banana = Banana.create!(name: 'Jeanette', apple: apples.first)
      banana2 = Banana.create!(name: 'Phasellus neque orci, porta a')

      link "/apples/#{apples.first.id}/bananas?append_to_name=123",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :ok
      assert_equal  ['Jeanette','Phasellus neque orci, porta a123'], apples.first.bananas.map(&:name)

      apples.first.bananas.delete(banana2)

      #
      # failure tests
      #

      # exception in allow block
      link "/apples/#{apples.first.id}/bananas?allow_bomb",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:103",
                   @response.body

      # exception in handler
      link "/apples/#{apples.first.id}/bananas?handler_bomb",
           headers: {"Link" => "<http://wwww.example.com/bananas/#{banana2.id}>; rel=\"related\""}.
             merge(mkhd(token: 'TOK_admin')),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_link handler: `Boom!' in test/files/parameterized_requests/apple.rb:109",
                   @response.body

    end
  end
end

require 'test_helper'
class UnlinkPluralAssociationTest < ActionDispatch::IntegrationTest
  context 'LINK requests to plural-association-URIs' do
    should 'remove association of source and target object'  do

      #
      # success tests
      #
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      bananas = Banana.create!([ {name: 'Integer placerat tristique nisl.', apple: apples.first},
                                 {name: 'Vivamus id enim.', apple: apples.first}])

      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :ok
      assert_equal 2, Banana.count
      assert_equal ['Vivamus id enim.'], apples.first.bananas.map(&:name)

      apples.first.bananas << bananas.first

      #
      # failure tests
      #

      # association not defined at all
      unlink "/apples/#{apples.first.id}/bananas_unknown",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "association `Apple#bananas_unknown' not configured", @response.body

      # unknown token
      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_unknown')),
             xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # unauthorized by allow block
      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_user')),
             xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:64",
                   @response.body

      # source not found
      unlink "/apples/999/bananas",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "Couldn't find Apple with 'id'=999", @response.body

      # target not found
      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "<http://wwww.example.com/bananas/888>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true


      assert_response :not_found
      assert_equal "Couldn't find Banana with 'id'=888", @response.body

      # UNLINK not configured

      unlink "/apples/#{apples.first.id}/bananas_surprise",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :method_not_allowed
      assert_equal "GET", @response.headers['Allow']
      assert_equal "UNLINK not configured", @response.body

      # Link header missing
      unlink "/apples/#{apples.first.id}/bananas",
             headers:mkhd(token: 'TOK_admin'),
             xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # Link header invalid
      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "abcbdedef<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :bad_request
      assert_equal "Link header missing or invalid", @response.body

      # target is not AR model
      unlink "/apples/#{apples.first.id}/bananas",
             headers: {"Link" => "<http://wwww.example.com/strings/100>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :not_found
      assert_equal "target class `String' is not an `ActiveRecord'", @response.body



    end
  end
  context 'LINK requests to plural-association-URIs with parameters' do
    should 'remove association of source and target object'  do

      #
      # success tests
      #
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      bananas = Banana.create!([ {name: 'Integer placerat tristique nisl.', apple: apples.first},
                                 {name: 'Vivamus id enim.', apple: apples.first}])

      unlink "/apples/#{apples.first.id}/bananas?mark_removed",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :ok
      assert_equal 2, Banana.count
      assert_equal ['Vivamus id enim.'], apples.first.bananas.map(&:name)
      assert_equal 'Integer placerat tristique nisl. (removed)', bananas.first.reload.name

      apples.first.bananas << bananas.first

      #
      # failure tests
      #

      # exception in allow block
      unlink "/apples/#{apples.first.id}/bananas?allow_bomb",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:116",
                   @response.body

      # exception in handler
       unlink "/apples/#{apples.first.id}/bananas?handler_bomb",
             headers: {"Link" => "<http://wwww.example.com/bananas/#{bananas.first.id}>; rel=\"related\""}.
               merge(mkhd(token: 'TOK_admin')),
             xhr: true

       assert_response :internal_server_error
       assert_equal "exception raised in via_unlink handler: `Boom!' in test/files/parameterized_requests/apple.rb:122",
                    @response.body
    end
  end
end

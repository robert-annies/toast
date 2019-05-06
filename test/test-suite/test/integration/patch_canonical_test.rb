require 'test_helper'
class PatchCanonicalTest < ActionDispatch::IntegrationTest
  context 'PATCH requests to canonical-URIs' do
    should "update a the object" do
      #
      # success tests
      #
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      patch "/apples/#{apples.second.id}",
            params: {name: 'Fringilla'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :ok

      assert_equal( {"name"             => 'Fringilla',
                     "number"           => 1092,
                     "kind"             => 'tree fruit',
                     "self"             => "http://www.example.com/apples/#{apples.second.id}",
                     "bananas"          => "http://www.example.com/apples/#{apples.second.id}/bananas",
                     "bananas_surprise" => "http://www.example.com/apples/#{apples.second.id}/bananas_surprise",
                     "first"            => "http://www.example.com/apples/first",
                     "all"              => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      assert_equal 'Fringilla', apples.second.reload['name']

      # for backward compatibilty
      put "/apples/#{apples.second.id}",
            params: {name: 'Ornare'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :ok

      assert_equal( {"name"             => 'Ornare',
                     "number"           => 1092,
                     "kind"             => 'tree fruit',
                     "self"             => "http://www.example.com/apples/#{apples.second.id}",
                     "bananas"          => "http://www.example.com/apples/#{apples.second.id}/bananas",
                     "bananas_surprise" => "http://www.example.com/apples/#{apples.second.id}/bananas_surprise",
                     "first"            => "http://www.example.com/apples/first",
                     "all"              => "http://www.example.com/apples"},
                    JSON.parse(@response.body) )

      assert_equal 'Ornare', apples.second.reload['name']

      # ignore any unknown attribues in payload
      patch "/apples/#{apples.third.id}",
            params: {name: 'Vodoo',
                     color: 'blue',
                     sweet: 'true'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :ok

      assert_equal( {"name"             => 'Vodoo',
                     "number"           => 1944,
                     "kind"             => 'tree fruit',
                     "self"             => "http://www.example.com/apples/#{apples.third.id}",
                     "bananas"          => "http://www.example.com/apples/#{apples.third.id}/bananas",
                     "bananas_surprise" => "http://www.example.com/apples/#{apples.third.id}/bananas_surprise",
                     "first"            => "http://www.example.com/apples/first",
                     "all"              => "http://www.example.com/apples"},
                    JSON.parse(@response.body) )

      assert_equal 'Vodoo', apples.third.reload['name']

      #
      # failure tests
      #

      # not found
      patch "/apples/999",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true


      assert_response :not_found
      assert_equal "Couldn't find Apple with 'id'=999", @response.body

      banana = Banana.create

      # PATCH no defined
      patch "/bananas/#{banana.id}",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :method_not_allowed
      assert_equal 'GET', @response.headers['Allow']

      # unauthorized by allow block
      patch "/apples/#{apples.second.id}",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_user'),
            xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:12",
                   @response.body

      # unknown token
      patch "/apples/#{apples.second.id}",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_unknown'),
            xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed",
                   @response.body

      # resource not exposed
      patch "/oranges/123",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :not_found
      assert_equal "no API configuration found for endpoint /oranges/123", @response.body

      # aborted by callback
      apples.second.update_column :number, 444
      patch "/apples/#{apples.second.id}",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :conflict
      assert_equal "patch of Apple##{apples.second.id} aborted: before_save callback threw :abort",
                   @response.body

      # validation failed
      apples.second.update_column :number, 555
      patch "/apples/#{apples.second.id}",
            params: {name: 'Ullamcorper'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :conflict
      assert_equal "patch of Apple##{apples.second.id} aborted: Number is invalid",
                   @response.body

    end
  end
  context 'PATCH requests to canonical-URIs with URI params' do
    should "update a the object" do
      #
      # success tests
      #
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      patch "/apples/#{apples.second.id}?remember_value",
            params: {name: 'Fringilla'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      patch "/apples/#{apples.second.id}?remember_value",
            params: {name: 'Parturient'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :ok
      assert_equal( {"name"   => 'Parturient',
                     "number" => 1092,
                     "self"   => "http://www.example.com/apples/#{apples.second.id}",
                     "bananas"=> "http://www.example.com/apples/#{apples.second.id}/bananas",
                     "pluck"  => "http://www.example.com/apples/pluck",
                     "steal"  => "http://www.example.com/apples/steal",
                     "all"  => "http://www.example.com/apples"},
                    JSON.parse(@response.body) )

      assert_equal  ['ullamcorper','Fringilla'], apples.second.reload.name_history

      #
      # failure tests
      #

      # allow block raises exception
      patch "/apples/#{apples.second.id}?remember_value&allow_bomb",
            params: {name: 'Pellentesque'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:23",
                   @response.body

      # handler raises exception
      patch "/apples/#{apples.second.id}?remember_value&handler_bomb",
            params: {name: 'Pellentesque'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_patch handler: `Boom!' in test/files/parameterized_requests/apple.rb:29",
                   @response.body

      # handler raises a 'bad_request'
      patch "/apples/#{apples.second.id}?remember_value&handler_bomb_badreq",
            params: {name: 'Pellentesque'}.to_json,
            headers: mkhd(token: 'TOK_admin'),
            xhr: true

      assert_response :bad_request
      assert_equal "`Poing!' in: test/files/parameterized_requests/apple.rb:30",
                   @response.body

    end
  end
end

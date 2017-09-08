require 'test_helper'
class GetSingularAssociationTest < ActionDispatch::IntegrationTest

  context 'GET requests to singular-association-URIs' do
    ###
    # parameterless request
    ###
    should 'return a single associated object' do
      #
      # success tests
      #
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      banana = Banana.create!(name: 'Ligula', number: 29, apple: apples.second)

      get "/bananas/#{banana.id}/apple",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"             =>'et',
                      "number"           => 189,
                      "kind"             => 'tree fruit',
                      "self"             => "http://www.example.com/apples/#{apples.second.id}",
                      "bananas"          => "http://www.example.com/apples/#{apples.second.id}/bananas",
                      "bananas_surprise" =>"http://www.example.com/apples/#{apples.second.id}/bananas_surprise",
                      "first"            => "http://www.example.com/apples/first",
                      "all"              => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

      # toast select
      get "/bananas/#{banana.id}/apple?toast_select=name,number,all",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"             =>'et',
                      "number"           => 189,                      
                      "all"              => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      #
      # failure tests
      #

      # association not defined at all
      get "/bananas/#{banana.id}/apple_unknown",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "association `Banana#apple_unknown' not configured", @response.body

      # return unexpected object
      get "/bananas/#{banana.id}/apple_surprise",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_equal "singular association returned `Time', expected `Apple'", @response.body

      # unknown token
      get "/bananas/#{banana.id}/apple",
          headers:  mkhd(token: 'TOK_unknown'),
          xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body


      # unauthorized by allow block
      get "/bananas/#{banana.id}/apple",
          headers:  mkhd(token: 'TOK_user'),
          xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/banana.rb:30",
                   @response.body


    end
  end

  context 'GET requests to singular-association-URIs with URI params'  do
    ###
    # parameterized request
    ###
    should "return a single object with URI params" do
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #
      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'Rumpelstilzchen', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      banana = Banana.create!(name: 'Ligula', number: 29, apple: apples.second)


      get "/bananas/#{banana.id}/apple",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal({
                     "name"    => '[FILTERED]', # reuqires ?secret
                     "number"  => 189,
                     "self"    => "http://www.example.com/apples/#{apples.second.id}",
                     "bananas" => "http://www.example.com/apples/#{apples.second.id}/bananas",
                     "pluck"   => "http://www.example.com/apples/pluck",
                     "steal"   => "http://www.example.com/apples/steal",
                     "all"     => "http://www.example.com/apples"

                   },
                   JSON.parse(@response.body) )

      get "/bananas/#{banana.id}/apple?secret=hellokitty",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    => 'Rumpelstilzchen',
                      "number"  => 189,
                      "self"    => "http://www.example.com/apples/#{apples.second.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.second.id}/bananas",
                      "pluck"   => "http://www.example.com/apples/pluck",
                      "steal"   => "http://www.example.com/apples/steal",
                      "all"     => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      #
      # failure tests
      #

      get "/bananas/#{banana.id}/apple?secret=hellodoggy",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match "exception from via_get handler: Wuff!",
                   @response.body


    end
  end
end

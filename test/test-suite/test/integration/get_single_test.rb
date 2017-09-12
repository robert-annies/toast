require 'test_helper'
class GetSingleTest < ActionDispatch::IntegrationTest

  context 'GET requests to single-URIs' do
    ###
    # parameterless request
    ###
    should "return a single object" do
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/first",
          headers: mkhd(:accept => "application/apple+json",
                        :token  => "TOK_admin"),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"             => 'nonumy',
                      "number"           => 92,
                      "kind"             => 'tree fruit',
                      "self"             => "http://www.example.com/apples/#{apples.first.id}",
                      "bananas"          => "http://www.example.com/apples/#{apples.first.id}/bananas",
                      "bananas_surprise" => "http://www.example.com/apples/#{apples.first.id}/bananas_surprise",
                      "first"            => "http://www.example.com/apples/first",
                      "all"              => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

      # toast select
      get "/apples/first?toast_select=kind,typo,self",
          headers: mkhd(:accept => "application/apple+json",
                        :token  => "TOK_admin"),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "kind"             => 'tree fruit',
                      "self"             => "http://www.example.com/apples/#{apples.first.id}",
                    },
                    JSON.parse(@response.body) )

      #
      # failure tests
      #

      Apple.destroy_all
      get "/apples/first", headers: mkhd(token: 'TOK_admin') , xhr: true
      assert_response :not_found

      # raises exception
      get "/bananas/first",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match "exception raised in handler: `This should never happen!'", @response.body

      # returns unexpected object
      get "/bananas/last",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_equal "single method returned `OpenStruct', expected `Banana'", @response.body

      # not defined at all
      get "/apples/second",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "collection or single `second' not configured in: test/files/toast_config_default_handlers/apple.rb",
                   @response.body

      # unknown token
      get "/apples/first",
          headers: mkhd(token: 'TOK_unknown'),
          xhr: true
      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # known token but unauthorized
      get "/apples/first",
          headers: mkhd(token: 'TOK_user'),
          xhr: true
      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:25",
                   @response.body
    end

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
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/pluck?num_equals=952",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'Neque',
                      "number"  => 952,
                      "self"    => "http://www.example.com/apples/#{apples.third.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                      "pluck"   => "http://www.example.com/apples/pluck",
                      "steal"   => "http://www.example.com/apples/steal",
                      "all"     => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

      #
      # failure tests
      #

      # the handler query cannot find anything
      get "/apples/pluck?num_equals=1010",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal 'resource not found at /apples/pluck', @response.body

      # wrong parameter causing an exception (passing 'array' of values)
      get "/apples/pluck?num_equals[0]=1&num_equals[1]=2;",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      if Rails::VERSION::MAJOR < 5 or Rails.version =~ /\A5.0/
        assert_response :internal_server_error
        assert_match "exception raised in handler: `SQLite3::SQLException: no such column: number.0:",
                     @response.body
      else
        # Rails >= 5.1 does not throw exception
        assert_response :not_found
        assert_equal "resource not found at /apples/pluck", @response.body
      end

      # wrong token
      get "/apples/pluck?num_equals=952",
          headers: mkhd(token: 'TOK_user'),
          xhr: true
      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/parameterized_requests/apple.rb:56",
                   @response.body

      # GET unconfigured (no via_get in single block)
      get "/apples/steal?num_equals=10",
          headers: mkhd(token: 'TOK_user'),
          xhr: true

      assert_response :method_not_allowed
      assert_equal "GET not configured", @response.body

    end
  end
end

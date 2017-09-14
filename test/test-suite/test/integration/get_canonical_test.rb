require 'test_helper'
class GetCanonicalTest < ActionDispatch::IntegrationTest
  ###
  # parameterless request
  ###
  context 'GET requests to canonical-URIs' do
    should 'return a single object' do
      #
      # success tests
      #
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/#{apples.third.id}",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'Neque',
                      "number"  => 952,
                      "kind"    => 'tree fruit',
                      "self"    => "http://www.example.com/apples/#{apples.third.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                      "bananas_surprise"=>"http://www.example.com/apples/#{apples.third.id}/bananas_surprise",
                      "first"  => "http://www.example.com/apples/first",
                      "all"    => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

      # toast_select

      get "/apples/#{apples.third.id}?toast_select=name,kind,first,unknown",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'Neque',
                      "kind"    => 'tree fruit',                     
                      "first"  => "http://www.example.com/apples/first"
                    },
                    JSON.parse(@response.body) )

      #
      # failure tests
      #

      # not found
      get "/apples/78",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "Apple#78 not found", @response.body

      # GET not defined
      Toast.init 'test/files/no_get_defined.rb'

      get "/apples/#{apples.first.id}",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      # HTTP 1.1 requirement
      # 6.5.5.  405 Method Not Allowed
      #
      #    The 405 (Method Not Allowed) status code indicates that the method
      #    received in the request-line is known by the origin server but not
      #    supported by the target resource.  The origin server MUST generate an
      #    Allow header field in a 405 response containing a list of the target
      #    resource's currently supported methods.

      assert_response :method_not_allowed
      assert_equal 'DELETE, PATCH', @response.headers['Allow']


      # unauthorizeed by allow block

      Toast.init 'test/files/get_canonical_auth.rb',
                 'test/files/settings-basic-auth.rb'

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json",
                    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials('john','abc')},
          xhr: true

      assert_response :ok

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json",
                    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials('carl','xyz')},
          xhr: true

      assert_response :unauthorized
      assert_equal "authorization failed", @response.body

      # unauthorized by allow block, with custom response headers and body
      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json",
                    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials('mark','xyz')},
          xhr: true

      assert_response :unauthorized
      assert_equal "authorization failed epically", @response.body
      assert_equal "#823745smvf", @response.headers['X-Confusing-Custom-Header']

      # resource not exposed
      Toast.init 'test/files/toast_config_default_handlers/*'

      get "/oranges/2943", xhr: true

      assert_response :not_found
      assert_equal "no API configuration found for endpoint /oranges/2943", @response.body

      # exception from allow handler
      Toast.init 'test/files/get_canonical_allow_exception.rb'

      get "/apples/#{apples.third.id}", xhr: true

      assert_response :internal_server_error
      assert_equal "exception from via_get handler: This should never happen!", @response.body

    end
  end
  context 'GET requests to canonical-URIs with parameters' do
    should 'return a single object' do
      #
      # success tests
      #
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/#{apples.third.id}?filter=name",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'[FILTERED]',
                      "number"  => 952,
                      "self"    => "http://www.example.com/apples/#{apples.third.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                      "pluck"  => "http://www.example.com/apples/pluck",
                      "steal"  => "http://www.example.com/apples/steal",
                      "all"    => "http://www.example.com/apples"
                    },
                    JSON.parse(@response.body) )

      #
      # failure tests
      #
      get "/apples/#{apples.third.id}?filter=wtf",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match /exception from via_get handler: undefined method `wtf=' for #<Apple/,
                   @response.body

      get "/objects/#{apples.third.id}?filter=wtf",
          headers: mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "no API configuration found for endpoint /objects/3",
                   @response.body



    end

  end
end

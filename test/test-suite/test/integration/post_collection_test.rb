require 'test_helper'
class PostCollectionTest < ActionDispatch::IntegrationTest
  ###
  # parameterless request
  ###
  context 'POST requests to collection-URIs' do
    should "create and return the new object" do

      #
      # success tests
      #

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      post "/apples",
           params: {name: 'Henry', number: 628}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :created

      new_id = Apple.find_by_name('Henry').id

      assert_equal( {"name"   => 'Henry',
                     "number" => 628,
                     "kind"   => 'tree fruit',
                     "self"   => "http://www.example.com/apples/#{new_id}",
                     "bananas"=> "http://www.example.com/apples/#{new_id}/bananas",
                     "bananas_surprise"=>"http://www.example.com/apples/#{new_id}/bananas_surprise",
                     "first"  => "http://www.example.com/apples/first",
                     "all"    => "http://www.example.com/apples"
                    },

                    JSON.parse(@response.body) )

      assert_equal 4, Apple.count

      # same behaviour for /apples/all
      post "/apples/all",
           params: {name: 'Konopelski', number: 828}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :created

      new_id = Apple.find_by_name('Konopelski').id

      assert_equal( {"name"   => 'Konopelski',
                     "number" => 828,
                     "kind"   => 'tree fruit',
                     "self"   => "http://www.example.com/apples/#{new_id}",
                     "bananas"=> "http://www.example.com/apples/#{new_id}/bananas",
                     "bananas_surprise"=>"http://www.example.com/apples/5/bananas_surprise",
                     "first"  => "http://www.example.com/apples/first",
                     "all"    => "http://www.example.com/apples"},
                    JSON.parse(@response.body) )

      assert_equal 5, Apple.count

      # try to set a read-only
      post "/bananas",
           params: {curvature: 90, number: 828}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true


      assert_response :created
      assert_equal({"name"      => nil,
                    "curvature" => nil,
                    "number"    => 828,
                    "self"      => "http://www.example.com/bananas/1",
                    "apple"     =>"http://www.example.com/bananas/1/apple",
                    "apple_surprise" => "http://www.example.com/bananas/1/apple_surprise",
                    "coconuts"  => "http://www.example.com/bananas/1/coconuts",
                    "first"     => "http://www.example.com/bananas/first",
                    "last"      => "http://www.example.com/bananas/last",
                    "query"     => "http://www.example.com/bananas/query",
                    "all"       => "http://www.example.com/bananas",
                    "all_wrong" => "http://www.example.com/bananas/all_wrong",
                    "no_collection" => "http://www.example.com/bananas/no_collection",
                    "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"},
                   JSON.parse(@response.body))

      #
      # failure tests
      #

      # collection not defined at all
      post "/coconuts",
           params: {name: 'Henry', number: 628}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :not_found
      assert_equal "collection `/coconuts' not configured", @response.body

      # unknown token
      post "/apples",
           params: {name: 'Henry', number: 917}.to_json,
           headers:  mkhd(token: 'TOK_unknown'),
           xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # not allowed by allow block
      post "/apples",
           params: {name: 'Henry', number: 917}.to_json,
           headers:  mkhd(token: 'TOK_user'),
           xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:80",
                   @response.body

      # POST not configured
      post "/dragonfruits",
           params: {name: 'Henry', number: 917}.to_json,
           headers:  mkhd(token: 'TOK_user'),
           xhr: true

      assert_response :method_not_allowed
      assert_equal "POST not configured",
                   @response.body

      # abort by before_* callback
      post "/bananas",
           params: {name: 'forbidden'}.to_json,
           headers: mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :conflict
      assert_equal 'creation of Banana aborted: before_create callback threw :abort',
                   @response.body

      # validation failed
      post "/bananas",
           params: {number: 15553}.to_json,
           headers: mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :conflict
      assert_equal 'creation of Banana aborted: Number is invalid',
                   @response.body

    end
  end

  ###
  # request with parameters
  ###
  context 'POST request to collection-URIs with URI params' do
    should 'create and return the new object by condition' do
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      #
      # success tests
      #

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      post "/apples?with=banana",
           params: {name: 'Henry', number: 628}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :created

      new_id = Apple.find_by_name('Henry').id

      assert_equal( {"name"   => 'Henry',
                     "number" => 628,
                     "self"   => "http://www.example.com/apples/#{new_id}",
                     "bananas"=> "http://www.example.com/apples/#{new_id}/bananas",
                     "all"    => "http://www.example.com/apples",
                     "pluck"    => "http://www.example.com/apples/pluck",
                     "steal"    => "http://www.example.com/apples/steal"
                    },
                    JSON.parse(@response.body) )

      banana = Apple.find(new_id).bananas.first
      assert_equal  'Ullamcorper Nibh Sollicitudin', banana.name

      post "/apples",
           params: {name: 'Etiam Fusce', number: 23}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      apple = Apple.find_by_name 'Etiam Fusce'
      assert_equal 0, apple.bananas.length

      #
      # failure tests
      #

      post "/apples?with=bomb",
           params: {name: 'Henry', number: 628}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_post handler: `Boom!' in test/files/parameterized_requests/apple.rb:151", @response.body

    end
  end
end

require 'test_helper'
class PostPluralAssociationTest < ActionDispatch::IntegrationTest
  ###
  # parameterless request
  ###
  context 'POST requests to plural-association-URIs' do
    should "create, link and return the new object" do

      #
      # success tests
      #

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      apples.second.bananas.create!({name: 'laudantium', number: 111})

      post "/apples/#{apples.second.id}/bananas",
           params: {"name" => "Sammie", "number" => 990, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :created

      new_id = Banana.find_by_name('Sammie').id
      assert_equal( {"name"              => 'Sammie',
                     "number"            => 990,
                     "curvature"         => nil, # read only
                     "apple"             => "http://www.example.com/bananas/#{new_id}/apple",
                     "apple_surprise"    => "http://www.example.com/bananas/#{new_id}/apple_surprise",
                     "self"              => "http://www.example.com/bananas/#{new_id}",
                     "coconuts"          => "http://www.example.com/bananas/#{new_id}/coconuts",
                     "first"             => "http://www.example.com/bananas/first",
                     "last"              => "http://www.example.com/bananas/last",
                     "query"             => "http://www.example.com/bananas/query",
                     "all"               => "http://www.example.com/bananas",
                     "all_wrong"         => "http://www.example.com/bananas/all_wrong",
                     "no_collection"     => "http://www.example.com/bananas/no_collection",
                     "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"},
                    JSON.parse(@response.body) )

      assert_equal 2, apples.second.bananas.count

      #
      # failure tests
      #

      # assoc not defined at all
      post "/apples/#{apples.second.id}/bananas_unknown",
           params: {"name" => "Sammie", "number" => 990, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :not_found
      assert_equal "association `Apple#bananas_unknown' not configured", @response.body

      # resource not found
      post "/apples/999/bananas",
           params: {"name" => "Sammie", "number" => 990, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :not_found
      assert_equal "Apple#999 not found", @response.body

      # not allowed
      post "/apples/#{apples.second.id}/bananas",
           params: {"name" => "Sammie", "number" => 990, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_user'),
           xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:52",
                   @response.body


      # abort by before_* callback
      post "/apples/#{apples.second.id}/bananas",
           params: {"name" => "forbidden", "number" => 990, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :conflict
      assert_equal 'creation of Banana aborted: before_create callback threw :abort',
                   @response.body

      # validation failed
      post "/apples/#{apples.second.id}/bananas",
           params: {"name" => "Tobias", "number" => 12555, "curvature" => 12}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :conflict
      assert_equal 'creation of Banana aborted: Number is invalid',
                   @response.body

    end
  end
  context 'POST requests to plural-association-URIs with parameters' do
    should "create, link and return the new object" do

      #
      # success tests
      #

      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      apples.second.bananas.create!({name: 'laudantium', number: 111})

      post "/apples/#{apples.second.id}/bananas?set_curvature=300",
           params: {"name" => "Sammie", "number" => 990}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :created
      new_id = Banana.find_by_name('Sammie').id
      assert_equal( {"name"              => 'Sammie',
                     "number"            => 990,
                     "curvature"         => 300, # read only (set by param)
                     "apple"             => "http://www.example.com/bananas/#{new_id}/apple",
                     "self"              => "http://www.example.com/bananas/#{new_id}",
                     "first"             => "http://www.example.com/bananas/first",
                     "query"             => "http://www.example.com/bananas/query",
                     "all"               => "http://www.example.com/bananas",
                     "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"},
                    JSON.parse(@response.body) )

      # exception from handler
      post "/apples/#{apples.second.id}/bananas?handler_bomb",
           params: {"name" => "Sammie", "number" => 990}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in via_post handler: `Boom!' in test/files/parameterized_requests/apple.rb:101",
                   @response.body

      # exception from allow block
      post "/apples/#{apples.second.id}/bananas?allow_bomb",
           params: {"name" => "Sammie", "number" => 990}.to_json,
           headers:  mkhd(token: 'TOK_admin'),
           xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:94",
                   @response.body
    end
  end
end

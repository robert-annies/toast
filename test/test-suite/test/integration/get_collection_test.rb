require 'test_helper'
class GetCollectionTest < ActionDispatch::IntegrationTest
  ###
  # parameterless request
  ###
  context 'GET request to collection-URIs' do
    should 'return an array of objects' do

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])


      #
      # success tests
      #

      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_same_elements([{
                              "name"             =>'nonumy',
                              "number"           => 92,
                              "kind"             => 'tree fruit',
                              "self"             => "http://www.example.com/apples/#{apples.first.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.first.id}/bananas",
                              "bananas_surprise" => "http://www.example.com/apples/#{apples.first.id}/bananas_surprise",
                              "first"            => "http://www.example.com/apples/first",
                              "all"              => "http://www.example.com/apples"
                            },{
                              "name"             =>'et',
                              "number"           => 189,
                              "kind"             => 'tree fruit',
                              "self"             => "http://www.example.com/apples/#{apples.second.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.second.id}/bananas",
                              "bananas_surprise" => "http://www.example.com/apples/#{apples.second.id}/bananas_surprise",
                              "first"            => "http://www.example.com/apples/first",
                              "all"              => "http://www.example.com/apples"
                            },{
                              "name"             =>'Neque',
                              "number"           => 952,
                              "kind"             => 'tree fruit',
                              "self"             => "http://www.example.com/apples/#{apples.third.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.third.id}/bananas",
                              "bananas_surprise" => "http://www.example.com/apples/#{apples.third.id}/bananas_surprise",
                              "first"            => "http://www.example.com/apples/first",
                              "all"              => "http://www.example.com/apples"
                            },{
                              "name"             =>'architecto',
                              "number"           => 26,
                              "kind"             => 'tree fruit',
                              "self"             => "http://www.example.com/apples/#{apples.fourth.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.fourth.id}/bananas",
                              "bananas_surprise" => "http://www.example.com/apples/#{apples.fourth.id}/bananas_surprise",
                              "first"            => "http://www.example.com/apples/first",
                              "all"              => "http://www.example.com/apples"
                            }],

                           JSON.parse(@response.body))


      assert_equal 'application/apples+json', @response.headers["content-type"]

      # toast_select
      get "/apples/all?toast_select=number,bananas,self",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_same_elements([{
                              "number"           => 92,
                              "self"             => "http://www.example.com/apples/#{apples.first.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.first.id}/bananas"
                            },{
                              "number"           => 189,
                              "self"             => "http://www.example.com/apples/#{apples.second.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.second.id}/bananas"
                            },{
                              "number"           => 952,
                              "self"             => "http://www.example.com/apples/#{apples.third.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.third.id}/bananas"
                            },{
                              "number"           => 26,
                              "self"             => "http://www.example.com/apples/#{apples.fourth.id}",
                              "bananas"          => "http://www.example.com/apples/#{apples.fourth.id}/bananas"
                            }],

                           JSON.parse(@response.body))


      # empty list
      Apple.destroy_all
      get "/apples/all", headers: mkhd(token: 'TOK_admin'), xhr: true
      assert_response :ok
      assert_equal [], JSON.parse(@response.body)


      #
      # failure tests
      #

      # not defined at all
      get "/apples/all_in_universe",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "collection or single `all_in_universe' not configured in: test/files/toast_config_default_handlers/apple.rb", @response.body

      # no configuration found
      get "/eggplants",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true
      assert_response :not_found
      assert_equal "no API configuration found for model `Eggplant'", @response. body

      # class method raises exception
      get "/bananas/all_wrong",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match /exception raised in via_get handler: `Crazy Diamond' in .*app\/models\/banana.rb:19/,
                   @response.body

      # return unexpected object
      get "/bananas/no_collection",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_equal "collection method returned OpenStruct, expected ActiveRecord::Relation of Banana", @response.body


      # unknown token
      get "/apples/all",
          headers: mkhd(token: 'TOK_unknown'),
          xhr: true
      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # known token but unauthorized
      get "/apples/all",
          headers: mkhd(token: 'TOK_user'),
          xhr: true
      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:74",
                   @response.body

    end
  end

  ###
  # request with parameters
  ###
  context 'GET request to collection-URIs with URI params' do
    should 'return an array of objects' do
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'


      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])


      #
      # success tests
      #
      get "/apples/all?less_than=100",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_same_elements([{
                              "name"    =>'nonumy',
                              "number"  => 92,
                              "self"    => "http://www.example.com/apples/#{apples.first.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.first.id}/bananas",
                              "pluck"   => "http://www.example.com/apples/pluck",
                              "steal"   => "http://www.example.com/apples/steal",
                              "all"     => "http://www.example.com/apples"
                            },{
                              "name"    =>'architecto',
                              "number"  => 26,
                              "self"    => "http://www.example.com/apples/#{apples.fourth.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.fourth.id}/bananas",
                              "pluck"   => "http://www.example.com/apples/pluck",
                              "steal"   => "http://www.example.com/apples/steal",
                              "all"     => "http://www.example.com/apples"
                            }],

                           JSON.parse(@response.body))


      assert_equal 'application/apples+json', @response.headers["content-type"]

      #
      # failure tests
      #

      # class method raises exception
      get "/apples//all?less_than=hello",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match /\Aexception from via_get handler in: .*SQLite3::SQLException: no such column: hello/,
                   @response.body

      # known token but unauthorized
      get "/apples/all?less_than=10",
          headers: mkhd(token: 'TOK_user'),
          xhr: true
      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/parameterized_requests/apple.rb:134",
                   @response.body

    end
  end

  ###
  # request with ranges
  ###
  context 'GET request to collection-URIs with ranges' do
    should 'return requested range' do

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!( (1..25).to_a.map{|n| {number: n}} )


      # default max_window size 10 is applied
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal 10, JSON.parse(@response.body).length
      assert_equal "items=0-9/25", @response.header['Content-Range']

      bananas = Banana.create!( (1..25).to_a.map{|n| {number: n}} )

      # max_window size is 7, set in config file
      get "/bananas/query?gt=11",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      prb = JSON.parse(@response.body)
      assert_equal 7, prb.length
      assert_equal (12..18).to_a, prb.map{|x| x['number']}
      assert_equal "items=0-6/14", @response.header['Content-Range']

      # request a range
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "5-9"),
          xhr: true

      assert_response :ok
      assert_equal 5, JSON.parse(@response.body).length
      assert_equal "items=5-9/25", @response.header['Content-Range']
      assert_equal [6,7,8,9,10], JSON.parse(@response.body).map{|x| x['number']}

      # request a range large than max_window=10
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "3-20"),
          xhr: true

      assert_response :ok
      assert_equal 10, JSON.parse(@response.body).length
      assert_equal "items=3-12/25", @response.header['Content-Range']
      assert_equal (4..13).to_a, JSON.parse(@response.body).map{|x| x['number']}

      # request a range omitting start
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "-3"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=0-3/25", @response.header['Content-Range']
      assert_equal (1..4).to_a, JSON.parse(@response.body).map{|x| x['number']}

      # request a range omitting end
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "21-"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=21-24/25", @response.header['Content-Range']
      assert_equal (22..25).to_a, JSON.parse(@response.body).map{|x| x['number']}

      # request a range omitting start and end
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "-"),
          xhr: true

      assert_response :ok
      assert_equal 10, JSON.parse(@response.body).length
      assert_equal "items=0-9/25", @response.header['Content-Range']
      assert_equal (1..10).to_a, JSON.parse(@response.body).map{|x| x['number']}

      # request an 'inverse' range (will ignore the range end)
      get "/apples/all",
          headers:  mkhd(token: 'TOK_admin', range: "21-10"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=21-24/25", @response.header['Content-Range']
      assert_equal (22..25).to_a, JSON.parse(@response.body).map{|x| x['number']}

      # empty result
      get "/bananas/query?gt=999999",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal 0, JSON.parse(@response.body).length
      assert_nil   @response.header['Content-Range']
    end
  end
end

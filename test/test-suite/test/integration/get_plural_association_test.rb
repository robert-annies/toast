require 'test_helper'
class GetPluralAssociationTest < ActionDispatch::IntegrationTest
  context 'GET requests to plural-association-URIs' do
    ###
    # parameterless request
    ###
    should 'return an array of associated objects'  do
      #
      # success tests
      #

      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      bananas1 = apples.first.bananas.create!([ {name: 'Purus',      number: 198, curvature: 39},
                                                {name: 'Dolor Cras', number: 592, curvature: 39},
                                                {name: 'Dapibus',    number: 36 , curvature: 39} ])

      bananas2 = apples.second.bananas.create!([ {name: 'Malesuada',  number: 189, curvature: 10},
                                                 {name: 'Neque',      number: 952, curvature: 10},
                                                 {name: 'architecto', number: 26 , curvature: 10} ])

      get "/apples/#{apples.second.id}/bananas",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok

      assert_same_elements( [{
                               "name"              =>'Malesuada',
                               "number"            => 189,
                               "curvature"         => 10,
                               "self"              => "http://www.example.com/bananas/#{bananas2.first.id}",
                               "apple"             => "http://www.example.com/bananas/#{bananas2.first.id}/apple",
                               "apple_surprise"    => "http://www.example.com/bananas/#{bananas2.first.id}/apple_surprise",
                               "coconuts"          =>"http://www.example.com/bananas/#{bananas2.first.id}/coconuts",
                               "first"             => "http://www.example.com/bananas/first",
                               "last"              => "http://www.example.com/bananas/last",
                               "query"             => "http://www.example.com/bananas/query",
                               "all"               => "http://www.example.com/bananas",
                               "all_wrong"         => "http://www.example.com/bananas/all_wrong",
                               "no_collection"     => "http://www.example.com/bananas/no_collection",
                               "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"

                             },{
                               "name"              =>'Neque',
                               "number"            => 952,
                               "curvature"         => 10,
                               "self"              => "http://www.example.com/bananas/#{bananas2.second.id}",
                               "apple"             => "http://www.example.com/bananas/#{bananas2.second.id}/apple",
                               "apple_surprise"    => "http://www.example.com/bananas/#{bananas2.second.id}/apple_surprise",
                               "coconuts"          =>"http://www.example.com/bananas/#{bananas2.second.id}/coconuts",
                               "first"             => "http://www.example.com/bananas/first",
                               "last"              => "http://www.example.com/bananas/last",
                               "query"             => "http://www.example.com/bananas/query",
                               "all"               => "http://www.example.com/bananas",
                               "all_wrong"         => "http://www.example.com/bananas/all_wrong",
                               "no_collection"     => "http://www.example.com/bananas/no_collection",
                               "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"
                             },{
                               "name"              =>'architecto',
                               "number"            => 26,
                               "curvature"         => 10,
                               "self"              => "http://www.example.com/bananas/#{bananas2.third.id}",
                               "apple"             => "http://www.example.com/bananas/#{bananas2.third.id}/apple",
                               "apple_surprise"    => "http://www.example.com/bananas/#{bananas2.third.id}/apple_surprise",
                               "coconuts"          =>"http://www.example.com/bananas/#{bananas2.third.id}/coconuts",
                               "first"             => "http://www.example.com/bananas/first",
                               "last"              => "http://www.example.com/bananas/last",
                               "query"             => "http://www.example.com/bananas/query",
                               "all"               => "http://www.example.com/bananas",
                               "all_wrong"         => "http://www.example.com/bananas/all_wrong",
                               "no_collection"     => "http://www.example.com/bananas/no_collection",
                               "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"
                             }],
                            JSON.parse(@response.body) )

      assert_equal 'application/bananas+json', @response.headers["content-type"]

      # toast_select
      get "/apples/#{apples.second.id}/bananas?toast_select=name",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok

      assert_same_elements( [{
                               "name"              =>'Malesuada'
                             },{
                               "name"              =>'Neque'
                             },{
                               "name"              =>'architecto'
                             }],
                            JSON.parse(@response.body) )

      get "/apples/#{apples.second.id}/bananas?toast_select=apple",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok

      assert_same_elements( [{
                               'apple' => "http://www.example.com/bananas/#{bananas2.first.id}/apple"
                             },{
                               'apple' => "http://www.example.com/bananas/#{bananas2.second.id}/apple"
                             },{
                               'apple' => "http://www.example.com/bananas/#{bananas2.third.id}/apple"
                             }],
                            JSON.parse(@response.body) )


      #
      # failure tests
      #

      # association not defined at all
      get "/apples/#{apples.second.id}/bananas_unknown",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :not_found
      assert_equal "association `Apple#bananas_unknown' not configured", @response.body

      # return unexpected object
      get "/apples/#{apples.second.id}/bananas_surprise",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_equal "plural association handler returned `Time', expected `ActiveRecord::Relation' (Banana)", @response.body

      # unknown token
      get "/apples/#{apples.second.id}/bananas",
          headers:  mkhd(token: 'TOK_unknown'),
          xhr: true

      assert_response :unauthorized
      assert_equal "authentication failed", @response.body

      # unauthorized by allow block
      get "/apples/#{apples.second.id}/bananas",
          headers:  mkhd(token: 'TOK_user'),
          xhr: true

      assert_response :unauthorized
      assert_equal "not authorized by allow block in: test/files/toast_config_default_handlers/apple.rb:46", @response.body


    end
  end
  ###
  # request with parameters
  ###
  context "GET requests to plural-association-URIs with parameters" do
    should 'return an array of associated objects'  do
      #
      # success tests
      #
      Toast.init 'test/files/parameterized_requests/*',
                 'test/files/settings-token-auth.rb'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      bananas1 = apples.first.bananas.create!([ {name: 'Purus',      number: 198, curvature: 39},
                                                {name: 'Dolor Cras', number: 592, curvature: 39},
                                                {name: 'Dapibus',    number: 36 , curvature: 39} ])

      bananas2 = apples.second.bananas.create!([ {name: 'Malesuada',  number: 189, curvature: 10},
                                                 {name: 'Neque',      number: 952, curvature: 10},
                                                 {name: 'Architecto', number: 26 , curvature: 10} ])

      get "/apples/#{apples.second.id}/bananas?sort_by=name",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_same_elements( [{
                               "name"              =>'Architecto',
                               "number"            => 26,
                               "curvature"         => 10,
                               "self"              => "http://www.example.com/bananas/#{bananas2.third.id}",
                               "apple"             => "http://www.example.com/bananas/#{bananas2.third.id}/apple",
                               "first"             => "http://www.example.com/bananas/first",
                               "query"             => "http://www.example.com/bananas/query",
                               "all"               => "http://www.example.com/bananas",
                               "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"

                             },{
                              "name"               =>'Neque',
                              "number"             => 952,
                              "curvature"          => 10,
                              "self"               => "http://www.example.com/bananas/#{bananas2.second.id}",
                              "apple"              => "http://www.example.com/bananas/#{bananas2.second.id}/apple",
                              "first"              => "http://www.example.com/bananas/first",
                              "query"              => "http://www.example.com/bananas/query",
                              "all"                => "http://www.example.com/bananas",
                              "less_than_hundred"  => "http://www.example.com/bananas/less_than_hundred"
                            },{
                               "name"              =>'Malesuada',
                               "number"            => 189,
                               "curvature"         => 10,
                               "self"              => "http://www.example.com/bananas/#{bananas2.first.id}",
                               "apple"             => "http://www.example.com/bananas/#{bananas2.first.id}/apple",
                               "first"             => "http://www.example.com/bananas/first",
                               "query"             => "http://www.example.com/bananas/query",
                               "all"               => "http://www.example.com/bananas",
                               "less_than_hundred" => "http://www.example.com/bananas/less_than_hundred"
                             }],
                            JSON.parse(@response.body) )


      #
      # failure tests
      #

      # SQL error
      get "/apples/#{apples.second.id}/bananas?sort_by=sun",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_match /exception raised: SQLite3::SQLException: no such column: sun/, @response.body

      # exception in allow block
      get "/apples/#{apples.second.id}/bananas?sort_by=name&allow_bomb",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :internal_server_error
      assert_equal "exception raised in allow block: `Boom!' in test/files/parameterized_requests/apple.rb:81",
                   @response.body

    end
  end

  ###
  # request with ranges
  ###
  context 'GET requests to plural-association-URIs with ranges' do
    should 'return requested range' do
      Toast.init 'test/files/toast_config_default_handlers/*',
                 'test/files/settings-token-auth.rb'

      toast_log = File.open('log/toast.log')
      toast_log.seek(0, IO::SEEK_END)


      apple = Apple.create
      apple.bananas.create!( (1..25).to_a.map{|n| {number: n}} )

      banana = apple.bananas.first
      banana.coconuts.create!((1..25).to_a.map{|n| {number: n}} )

      # default max_window size 10 is applied
      get "/apples/#{apple.id}/bananas",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      assert_equal 10, JSON.parse(@response.body).length
      assert_equal "items=0-9/25", @response.header['Content-Range']


      # max_window size is 7, set in config file
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin'),
          xhr: true

      assert_response :ok
      prb = JSON.parse(@response.body)
      assert_equal 7, prb.length
      assert_equal (1..7).to_a, prb.map{|x| x['number']}
      assert_equal "items=0-6/25", @response.header['Content-Range']
      assert_match /done: sent 7 records of Coconut/, toast_log.readlines.last

      # request a range
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "5-9"),
          xhr: true

      assert_response :ok
      assert_equal 5, JSON.parse(@response.body).length
      assert_equal "items=5-9/25", @response.header['Content-Range']
      assert_equal [6,7,8,9,10], JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 5 records of Coconut/, toast_log.readlines.last

      # request a range large than max_window=7
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "3-20"),
          xhr: true

      assert_response :ok
      assert_equal 7, JSON.parse(@response.body).length
      assert_equal "items=3-9/25", @response.header['Content-Range']
      assert_equal (4..10).to_a, JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 7 records of Coconut/, toast_log.readlines.last

      # request a range omitting start
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "-3"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=0-3/25", @response.header['Content-Range']
      assert_equal (1..4).to_a, JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 4 records of Coconut/, toast_log.readlines.last

      # request a range omitting end
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "21-"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=21-24/25", @response.header['Content-Range']
      assert_equal (22..25).to_a, JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 4 records of Coconut/, toast_log.readlines.last

      # request a range omitting start and end
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "-"),
          xhr: true

      assert_response :ok
      assert_equal 7, JSON.parse(@response.body).length
      assert_equal "items=0-6/25", @response.header['Content-Range']
      assert_equal (1..7).to_a, JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 7 records of Coconut/, toast_log.readlines.last

      # request an 'inverse' range (will ignore the range end)
      get "/bananas/#{banana.id}/coconuts",
          headers:  mkhd(token: 'TOK_admin', range: "21-10"),
          xhr: true

      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length
      assert_equal "items=21-24/25", @response.header['Content-Range']
      assert_equal (22..25).to_a, JSON.parse(@response.body).map{|x| x['number']}
      assert_match /done: sent 4 records of Coconut/, toast_log.readlines.last

      # empty list has no content-range
      Banana.delete_all
      get "/bananas",
          headers:  mkhd(token: 'TOK_admin', range: "-"),
          xhr: true

      assert_response :ok
      assert_equal 0, JSON.parse(@response.body).length
      assert_nil   @response.header['Content-Range']

    end
  end
end

require 'test_helper'
class HandlerTest < ActionDispatch::IntegrationTest

  context "non toast routes" do
    should "should be served" do
      Toast.init 'test/files/toast_config_default_handlers/*'
      get "/tomato"
      assert_response :ok
      assert_equal "A Tomato", @response.body
    end
  end

  context "default handlers" do
    should "respond to `singles' URIs with GET [F.1]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/first",
          headers: {"HTTP_ACCEPT"=>"application/apple+json"},
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'nonumy',
                      "number"  => 92,
                      "self"    => "http://www.example.com/apples/#{apples.first.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.first.id}/bananas",
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]


    end

    should "respond to `collection' URIs with GET [F.2]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/all",
          headers: {"HTTP_ACCEPT"=>"application/apple+json"},
          xhr: true

      assert_response :ok
      assert_same_elements([{
                              "name"    =>'nonumy',
                              "number"  => 92,
                              "self"    => "http://www.example.com/apples/#{apples.first.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.first.id}/bananas",
                            },{
                              "name"    =>'et',
                              "number"  => 189,
                              "self"    => "http://www.example.com/apples/#{apples.second.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.second.id}/bananas",
                            },{
                              "name"    =>'Neque',
                              "number"  => 952,
                              "self"    => "http://www.example.com/apples/#{apples.third.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                            },{
                              "name"    =>'architecto',
                              "number"  => 26,
                              "self"    => "http://www.example.com/apples/#{apples.fourth.id}",
                              "bananas" => "http://www.example.com/apples/#{apples.fourth.id}/bananas",
                            }],

                           JSON.parse(@response.body))


      assert_equal 'application/apples+json', @response.headers["content-type"]
    end

    should "respond to `canonical' URIs with GET [F.5]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json"},
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'Neque',
                      "number"  => 952,
                      "self"    => "http://www.example.com/apples/#{apples.third.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

    end

    should "respond to singular `association' URIs with GET [F.3]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([{name: 'nonumy', number: 92},
                              {name: 'et', number: 189},
                              {name: 'Neque', number: 952},
                              {name: 'architecto', number: 26}])

      get "/apples/#{apples.third.id}",
          headers: {"HTTP_ACCEPT"=>"application/apple+json"},
          xhr: true

      assert_response :ok
      assert_equal( {
                      "name"    =>'Neque',
                      "number"  => 952,
                      "self"    => "http://www.example.com/apples/#{apples.third.id}",
                      "bananas" => "http://www.example.com/apples/#{apples.third.id}/bananas",
                    },
                    JSON.parse(@response.body) )

      assert_equal 'application/apple+json', @response.headers["content-type"]

    end

    should "respond to plural `association' URIs with GET [F.4]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      bananas1 = apples.first.bananas.create!([ {name: 'Purus',      number: 198, curvature: 39},
                                                {name: 'Dolor Cras', number: 592, curvature: 39},
                                                {name: 'Dapibus',    number: 36 , curvature: 39} ])

      bananas2 = apples.second.bananas.create!([ {name: 'Malesuada',  number: 189, curvature: 10},
                                                 {name: 'Neque',      number: 952, curvature: 10},
                                                 {name: 'architecto', number: 26 , curvature: 10} ])

      get "/apples/#{apples.second.id}/bananas", xhr: true

      assert_response :ok
      assert_same_elements( [{
                               "name"    =>'Malesuada',
                               "number"  => 189,
                               "curvature" => 10,
                               "self"    => "http://www.example.com/bananas/#{bananas2.first.id}",
                               "apple" => "http://www.example.com/bananas/#{bananas2.first.id}/apple",
                             },{
                               "name"    =>'Neque',
                               "number"  => 952,
                               "curvature" => 10,
                               "self"    => "http://www.example.com/bananas/#{bananas2.second.id}",
                               "apple" => "http://www.example.com/bananas/#{bananas2.second.id}/apple",
                             },{
                               "name"    =>'architecto',
                               "number"  => 26,
                               "curvature" => 10,
                               "self"    => "http://www.example.com/bananas/#{bananas2.third.id}",
                               "apple" => "http://www.example.com/bananas/#{bananas2.third.id}/apple",
                             }],
                            JSON.parse(@response.body) )

      assert_equal 'application/bananas+json', @response.headers["content-type"]

    end

    should "respond to canonical URIs with PUT [F.6]" do
      Toast.init 'test/files/toast_config_default_handlers/*'

      apples = Apple.create!([ {name: 'nonumy', number: 952},
                               {name: 'ullamcorper', number: 1092},
                               {name: 'Etiam', number: 1944} ])

      put "/apples/#{apples.second.id}",
          params: {name: 'Fringilla'}.to_json,
          headers: {"content-type":"application/apple+json"},
          xhr: true

      assert_response :ok

      assert_equal( {"name"   => 'Fringilla',
                     "number" => 1092,
                     "self"   => "/apples/#{apples.second.id}",
                     "bananas"=>"http://www.example.com/#{apples.second.id}/bananas"},
                    JSON.parse(@response.body) )

    end

  end
end

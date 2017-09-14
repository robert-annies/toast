require 'test_helper'
class PostPluralAssociationTest < ActionDispatch::IntegrationTest
  context 'path prefixes' do
    should 'be resolved' do
      Toast.init 'test/files/under_path.rb'

      apples = Apple.create!( (1..3).to_a.map{|n| {number: n}} )
      bananas = Banana.create!( (1..4).to_a.map{|n| {number: n}} )
      coconuts = Coconut.create!( (1..5).to_a.map{|n| {number: n, banana: bananas.third}} )
      dragonfruits = Dragonfruit.create!( (1..6).to_a.map{|n| {number: n}} )
      eggplants = Eggplant.create!( (1..7).to_a.map{|n| {number: n}} )

      #
      # success tests
      #

      get '/fruits/apples', xhr: true
      assert_response :ok
      assert_equal 3, JSON.parse(@response.body).length

      get '/api/v1/bananas', xhr: true
      assert_response :ok
      assert_equal 4, JSON.parse(@response.body).length

      get "/api/v2/coconuts/#{coconuts.second.id}/banana", xhr: true
      assert_response :ok
      assert_equal "http://www.example.com/api/v1/bananas/#{bananas.third.id}",
                   JSON.parse(@response.body)['self']

      get "/api/v1/dragonfruits/#{dragonfruits.last.id}", xhr: true
      assert_response :ok
      assert_equal "http://www.example.com/api/v1/dragonfruits/#{dragonfruits.last.id}", 
                   JSON.parse(@response.body)['self']
     
      get "/eggplants/#{eggplants.second.id}", xhr: true
      assert_response :ok
      assert_equal "http://www.example.com/eggplants/#{eggplants.second.id}", 
                   JSON.parse(@response.body)['self']
      #
      # failure tests
      #
      get '/api/v1/apples', xhr: true
      assert_response :not_found
      assert_equal 'no API configuration found for endpoint /api/v1/apples', @response.body

      get '/api/v3/bananas', xhr: true
      assert_response :not_found
      assert_equal 'no API configuration found for endpoint /api/v3/bananas', @response.body

      get "/coconuts/#{coconuts.second.id}/banana", xhr: true
      assert_response :not_found
      assert_equal "no API configuration found for endpoint /coconuts/#{coconuts.second.id}/banana", @response.body

      get "/api/dragonfruits/#{dragonfruits.last.id}", xhr: true
      assert_response :not_found
      assert_equal "no API configuration found for endpoint /api/dragonfruits/#{dragonfruits.last.id}", @response.body

      get "/fruits/eggplants/#{eggplants.second.id}", xhr: true
      assert_response :not_found
      assert_equal "no API configuration found for endpoint /fruits/eggplants/#{eggplants.second.id}", @response.body    
     end
  end
end
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

require 'factory.rb'
include ModelFactory

Apple.delete_all
apples = create_records Apple, 20 do |r|
  r.name = Faker::Internet.email
  r.number = Faker::Number.integer 0..9999 
end

Banana.delete_all
bananas = create_records Banana, 50 do |r|
  r.name = Faker::Address.city
  r.number = Faker::Number.integer 0..9999 
  r.apple = choose(1, apples).first
end

CoconutDragonfruit.delete_all

Coconut.delete_all
coconuts = create_records Coconut, 30 do |r|
  r.name = Faker::Company.name
  r.number = Faker::Number.integer 0..9999 
  r.banana = choose(1, bananas).first
end

Dragonfruit.delete_all
dragonfruits = create_records Dragonfruit, 60 do |r|
  r.name = Faker::Address.street_address
  r.number = Faker::Number.integer 0..9999 
  r.banana = choose(1, bananas).first
  r.coconuts = choose(0..10, coconuts)
end

coconuts.each do |r|
  r.dragonfruits = choose(0..10, dragonfruits)
end

CoconutDragonfruit.all.each do |r|
  r.name = Faker::Address.us_state
  r.number = Faker::Number.integer 0..20
  r.save
end








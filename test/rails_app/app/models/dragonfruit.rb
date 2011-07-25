class Dragonfruit < ActiveRecord::Base

  has_one :banana

  has_many :coconut_dragonfruits
  has_many :coconuts, :through => :coconut_dragonfruits

  resourceful_model do    
    disallow_methods :put, :post, :get, :delete
    collections :all
  end
  
end

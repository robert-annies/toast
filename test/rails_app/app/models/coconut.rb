class Coconut < ActiveRecord::Base

  belongs_to :banana

  has_many :coconut_dragonfruits
  has_many :dragonfruits, :through => :coconut_dragonfruits

  resourceful_model do |r|
    r.fields = :name, :number
    r.collections = :all
    r.namespace = "fruits"
  end
end

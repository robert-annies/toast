class Coconut < ActiveRecord::Base

  belongs_to :banana

  has_many :coconut_dragonfruits
  has_many :dragonfruits, :through => :coconut_dragonfruits

  acts_as_resource do |r|
    r.namespace = "fruits"
    r.writables = :name, :number
    r.collections = :all
    r.postable
  end
end

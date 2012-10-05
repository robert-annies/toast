class Coconut < ActiveRecord::Base

  belongs_to :banana

  has_many :coconut_dragonfruits
  has_many :dragonfruits, :through => :coconut_dragonfruits

  serialize :object, Hash
  serialize :array, Array

  acts_as_resource do |r|
    r.namespace = "fruits"
    r.writables = :name, :number, :object, :array
    r.collections = :all
    r.postable
  end
end

class Dragonfruit < ActiveRecord::Base

  has_one :banana

  has_many :coconut_dragonfruits
  has_many :coconuts, :through => :coconut_dragonfruits
  belongs_to :eggplant

  acts_as_resource {
    writables :banana
    collections :all
    pass_params_to :self
  }

  attr_accessor :current_user


end

class Eggplant < ActiveRecord::Base
  has_many :dfruits, :class_name => "Dragonfruit"
  belongs_to :potato, :class_name => "Apple"
  has_many :bananas
  
  acts_as_resource do 
    media_type     "application/eggplant_+json"
    readables      :name, :number,  :dfruits, :potato , :bananas 
    singles        :first
  end
end

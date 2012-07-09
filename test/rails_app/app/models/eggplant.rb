class Eggplant < ActiveRecord::Base
  has_many :dfruits, :class_name => "Dragonfruit"
  belongs_to :potato, :class_name => "Apple"
  has_many :bananas

  has_many :bananas_scoped, 
           :class_name => "Banana", 
           :conditions => lambda { less_than_100 }
  
  acts_as_resource do 
    media_type     "application/eggplant_+json"
    readables      :name, :number,  :dfruits, :potato , :bananas 
  end
end

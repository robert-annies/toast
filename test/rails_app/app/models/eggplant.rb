class Eggplant < ActiveRecord::Base
  has_many :dfruits, :class_name => "Dragonfruit"
  belongs_to :potato, :class_name => "Apple"
  has_many :bananas
  has_and_belongs_to_many :apples

  acts_as_resource do
    media_type     "application/eggplant_+json"
    readables      :name, :number,  :dfruits, :potato , :bananas
    writables      :apples
    singles        :first
  end
end

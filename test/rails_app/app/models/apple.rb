class Apple < ActiveRecord::Base

  acts_as_resource do |resource|
    resource.media_type = "application/apple+json"
    resource.writables = :name, :number, :eggplants
    resource.readables = :bananas
    resource.collections = :all
    resource.singles = :first

    resource.in_collection do
      readables :number
    end

    resource.deletable
  end

  has_many :bananas
  has_and_belongs_to_many :eggplants
end

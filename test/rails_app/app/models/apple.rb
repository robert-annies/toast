class Apple < ActiveRecord::Base

  acts_as_resource do |resource|
    resource.media_type = "application/json+apple"
    resource.writables = :name, :number
    resource.readables = :bananas
    resource.collections = :all
    resource.singles = :first

    resource.in_collection do
      readables :number
    end

    resource.deletable
  end

  has_many :bananas
end

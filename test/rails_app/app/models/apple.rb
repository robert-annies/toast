class Apple < ActiveRecord::Base

  resourceful_model do |resource|
    resource.media_type = "application/json+apple"
    resource.fields = :name, :number, :bananas
    resource.collections = :all

    resource.in_collection do
      fields :number
    end
  end

  has_many :bananas
end

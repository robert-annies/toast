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

    resource.pass_params_to = :eggplants
  end

  has_many :bananas
  has_and_belongs_to_many :eggplants do
    def find_by_params params={'greater_than' => -10}
      where(['number > ?', params['greater_than'].to_i])
    end
  end
end

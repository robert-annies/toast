class Apple < ApplicationRecord

  has_many :bananas
  has_many :bananas_surprise, :class_name => 'Banana'
  has_and_belongs_to_many :eggplants

  serialize :name_history, Array

  before_destroy do
    if number == 1092
      errors.add(:base, 'before_destroy callback threw :abort')
      throw :abort
    end
  end

  before_save(on: :update) do
    if number == 444
      errors.add(:base, 'before_save callback threw :abort')
      throw :abort
    end
  end

  validates_format_of :number, without: /555/

  def self.steal
  end

  def self.some
    Apple.all[0..2]
  end

  def kind
    'tree fruit'
  end
end

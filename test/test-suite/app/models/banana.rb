class Banana < ApplicationRecord
  if Rails::VERSION::MAJOR < 5
    belongs_to :apple
  else
    belongs_to :apple, optional: true
  end

  has_one :apple_surprise, :class_name => 'Apple'
  has_many :coconuts

  scope :less_than_hundred, lambda { where("number < 100") }
  scope :query, lambda{|v| where(["number > ?", v])}

  before_create do
    if name == 'forbidden'
      errors.add(:base, "before_create callback threw :abort")
      if Rails::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    else
      true
    end
  end

  validates_format_of :number, without: /555/

  def self.all_wrong
    raise 'Crazy Diamond'
  end

  def self.no_collection
    OpenStruct.new(shine: :on)
  end

  def color
    "yellow"
  end

  def weight= w
  end

  def weight
    3
  end

  def self.first
    raise "This should never happen!"
  end

  def self.last
    OpenStruct.new(:unexpected => :object)
  end
end

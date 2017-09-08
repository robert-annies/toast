class Banana < ApplicationRecord
  belongs_to :apple
  has_many :coconuts

=begin
  belongs_to :dragonfruit


  acts_as_resource {
    media_type "application/banana-v1"

    writables :name, :number, :coconuts
    readables :curvature, :apple, :dragonfruit

    collections :less_than_100, :all, :query

    paginate :all, :page_size => 10
    paginate :query, :page_size => 30

    singles :first

    pass_params_to :query

    in_collection {
      media_type "application/bananas-v1"
    }
  }

  acts_as_resource {
    # add :color, removed :less_than_100
    media_type "application/banana-v2"

    writables :name, :number, :coconuts
    readables :curvature, :apple, :dragonfruit, :color

    singles :first
    collections :query
    pass_params_to :query

    in_collection {
      media_type "application/bananas-v2"
    }
  }
=end
  scope :less_than_hundred, lambda { where("number < 100") }
  scope :query, lambda{|v| puts self; where(["number > ?", v])}

  def curvature
    8.18
  end

  def color
    "yellow"
  end

  def weight= w
  end

  def weight
    3
  end
end

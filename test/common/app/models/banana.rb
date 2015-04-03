class Banana < ActiveRecord::Base
  belongs_to :apple
  belongs_to :dragonfruit

  has_many :coconuts

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

  scope :less_than_100, lambda { where("number < 100") }


  def self.query params
    where(["number > ?", params[:gt]])
  end

  def curvature
    8.18
  end

  def color
    "yellow"
  end

end

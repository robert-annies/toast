class Banana < ActiveRecord::Base
  belongs_to :apple
  belongs_to :dragonfruit

  has_many :coconuts

  resourceful_model do

    writables :name, :number
    readables :curvature, :coconuts, :apple, :dragonfruit

    collections :find_some, :all, :query
    pass_params_to :query

  end

  scope :find_some, where("number < 100")


  def self.query params
    where(["number > ?", params[:gt]])
  end

  def curvature
    8.18
  end
end

expose(Banana, as: 'application/banana+json') {


  writables :name, :number
  readables :curvature

  association(:apple)  {
    via_get {
      allow do |*args|
        true
      end

      allow do |*args|
        true
      end

      handler do |banana, uri_params|
        banana.apple if banana.apple.number > uri_params[:gt]
      end
    }
  }

  collection(:query) {
    via_get {
      allow do |*args|
        true
      end
      handler do |uri_params|
        Banana.where(["number > ?", uri_params[:gt]])
      end
    }
  }

  collection(:all) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:less_than_hundred) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

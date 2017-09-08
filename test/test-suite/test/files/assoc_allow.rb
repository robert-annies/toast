expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  association(:apple)  {
    via_get {
      allow do |auth, request_model, url_params|
        true
      end

      allow do |*args|
        true
      end
    }
  }

  collection(:query) {
    via_get {
      allow do |*args|
        true
      end
      handler do |uri_params|
        Banana.query(uri_params[:gt])
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

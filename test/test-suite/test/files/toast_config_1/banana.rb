expose(Banana, as: 'application/banana+json', under: 'test/api-v1/') {

  writables :name, :number, :weight
  readables :curvature

  single(:first) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  single(:last) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:apple)  {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:query) {
    max_window 99
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

=begin
expose(Banana, as: 'application/banana+json', under: 'test/api-v2/') {

  writables :name, :number, :weight
  readables :curvature

  single(:first) {
    via_get {
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
    }
  }
}
=end

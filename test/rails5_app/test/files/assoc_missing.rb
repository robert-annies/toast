expose(Banana, as: 'application/banana+json') {


  writables :name, :number
  readables :curvature

  association(:cherries)  { # <- missing
    via_get {
      allow do |*args|
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
      handler do |banana, options|
        options[:relation].where(["number > ?", options[:url_params][:gt]])
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

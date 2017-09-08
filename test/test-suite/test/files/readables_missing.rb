expose(Banana, as: 'application/banana+json') {


  writables :name, :number
  readables :curvature, :non_existent

  singles     :first

  association(:apple)  {
    via_get {
      allow do |user, options|
        true
      end

      allow do |user, options|
        true
      end
    }
  }

  collection(:query) {
    via_get {
      allow do |user, options|
        true
      end
      handler do |banana, options|
        options[:relation].where(["number > ?", options[:url_params][:gt]])
      end
    }
  }

  collection(:all) {
    via_get {
      allow do |user, options|
        true
      end
    }
  }

  collection(:less_than_hundred) {
    via_get {
      allow do |user, options|
        true
      end
    }
  }
}

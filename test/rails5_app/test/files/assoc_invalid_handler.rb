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

      handler do |relation, payload, url_params, foo| # <- too many args
        # wrong anyway
      end
    }

    via_link {
      allow do |*args|
        true
      end
    }

    via_unlink {
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
      handler do |relation, payload, url_params|
        relation.where(["number > ?", url_params[:gt]])
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

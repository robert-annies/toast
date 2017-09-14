expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  via_get {
    allow do |*args|
      true
    end
  }

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

  association(:apple, as: 'application/apple+json')  {
    via_get {
      allow do |role, relation, uri_params|
        role == :admin
      end
    }

    via_link {
      allow do  |role, relation, uri_params|
        role == :admin
      end
    }

    via_unlink {
      allow do  |role, relation, uri_params|
        role == :admin
      end
    }
  }

  association(:apple_surprise) {
    via_get {
      allow do |*args|
        true
      end

      handler do |apple, uri_params|
        Time.now
      end
    }
  }

  association(:coconuts) {
    max_window 7
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:query) {
    max_window 7
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

    via_post {
      allow do |*args|
        true
      end
    }
  }

  collection(:all_wrong) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:no_collection) {
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

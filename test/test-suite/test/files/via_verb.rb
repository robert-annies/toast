expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  via_get {
      allow do |*args|
        true
      end
    }

  via_patch {
    allow do |*args|
      true
    end
  }

  via_delete {
    allow do |*args|
      true
    end
  }

  association(:apple)  {
    via_get {
      allow do |*args|
        true
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

  association(:coconuts) {
    via_post {
      allow do |*args|
        true
      end
    }

    via_get {
      allow do |*args|
        true
      end

      #handler do |source, uri_params|
      #  source.coconuts.where(["number > ?", options[:url_params][:gt]])
      #end
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

    via_post {
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

  single(:first) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

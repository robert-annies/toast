expose(Apple, as: 'application/apple+json') {
  writables   :name, :number

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

  association(:bananas, :as => 'application/bananas+json') {
    max_window 100
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:all, :as => 'application/apples+json') {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

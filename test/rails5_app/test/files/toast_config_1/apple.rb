
expose(Apple, as: 'application/apple+json') {
  writables   :name, :number
  single(:first) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:bananas) {
    max_window 100
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:eggplants) {
    via_get {
      allow do |*args|
        true
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
}

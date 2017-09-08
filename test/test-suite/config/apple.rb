expose(Apple, as: 'application/apple+json') {

  writables   :name, :number

  collection(:all) {
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

  association(:bananas) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

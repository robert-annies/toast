expose(String, as: 'application/apple+json') {
  deletable
  writables   :name, :number

  singles     :first

  association(:bananas) {
    via_get {
      allow do |user, options|
        true
      end
    }
  }
}

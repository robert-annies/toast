expose(Coconut, as: 'application/coconut+json') {

  writables :name, :number

  via_get {
    allow do |*args|
      true
    end
  }
}

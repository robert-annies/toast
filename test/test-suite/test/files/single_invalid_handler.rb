expose(Banana, as: 'application/banana+json') {


  writables :name, :number
  readables :curvature

  single(:last) {
    via_get {
      allow{|*args| true}
      handler do |one, two| # wrong number of args
        two
      end
    }
  }
}

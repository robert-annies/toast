expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  association(:apple) {
    good_morning
  }
}

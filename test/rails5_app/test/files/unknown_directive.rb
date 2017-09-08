expose(Banana, as: 'application/banana+json') {

  writables :name, :number
  readables :curvature

  good_morning
}

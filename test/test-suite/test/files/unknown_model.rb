expose(Cherry, as: 'application/cherry+json') {
  writables   :name, :number
  singles     :first
}

expose(String) {
  writables   :name, :number
  singles     :first
}

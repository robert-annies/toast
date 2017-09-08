toast_settings {
  maxx_window 1090
  link_unlink_via_post true

  authenticate do |request|
    request.capitalize
  end
}

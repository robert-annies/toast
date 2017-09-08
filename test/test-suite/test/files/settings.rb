toast_settings {
  max_window 1090
  link_unlink_via_post true

  authenticate do |request|
    request.capitalize
  end
}

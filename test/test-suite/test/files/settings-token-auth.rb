toast_settings {
  max_window 10
  link_unlink_via_post false

  authenticate do |request|
    token, options = ActionController::HttpAuthentication::Token.token_and_options(request)

    case token
    when "TOK_admin"
      :admin
    when "TOK_user"
      :user
    else
      false
    end
  end
}

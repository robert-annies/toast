toast_settings {
  max_window 10
  link_unlink_via_post false

  authenticate do |request|
    ActionController::HttpAuthentication::Basic.authenticate(request) do |login,password|
      case [login,password]
      when ['john','abc']
        'john'
      when ['carl','xyz']
        'carl'
      when ['mark', 'xyz']
        fail_with :headers => {'X-Confusing-Custom-Header'=>'#823745smvf'},
                  :body => 'authorization failed epically',
                  :status => :unauthorized
      else
        false
      end
    end
  end
}

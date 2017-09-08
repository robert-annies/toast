Rails.application.routes.draw do
  # non-toast route
  match '/tomato', to: -> (hash) { [200, {}, ['A Tomato']]}, via: :get

end

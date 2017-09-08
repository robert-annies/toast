Rails.application.routes.draw do
  mount Toast::RackApp.new, at: '/*toast_path'
end

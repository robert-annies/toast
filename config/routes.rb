Rails.application.routes.draw do
  match '*toast_path', to: Toast::RackApp.new,  via: :all
end

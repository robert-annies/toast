class ToastGenerator < Rails::Generators::NamedBase

  source_root File.expand_path("../templates", __FILE__)

  def init
   	template "toast-api.rb.erb", 'config/toast-api.rb' 
    empty_directory "config/toast-api/"
  end
end
require 'toast/active_record_extensions.rb'
require 'toast/resource.rb'
require 'toast/root_collection'
require 'toast/associate_collection'
require 'toast/attribute'
require 'toast/record'
require 'action_dispatch/http/request'

module Toast
  class Engine < Rails::Engine

    # configure our plugin on boot. other extension points such
    # as configuration, rake tasks, etc, are also available
    initializer "toast.initialize" do |app|
      # Add 'restful_model' declaration to ActiveRecord::Base
      ActiveRecord::Base.extend Toast::ActiveRecordExtensions

      # Load all models in app/models
      Dir["#{Rails.root}/app/models/**/*.rb"].each{|m| require m }
    end
  end
end

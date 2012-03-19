Rails.application.routes.draw do

  ActiveRecord::Base.descendants.each do |model|
    next unless model.is_resourceful_model?

    resource_name = model.to_s.pluralize.underscore

    match("#{model.toast_config.namespace}/#{resource_name}(/:id(/:subresource))" => 'toast#catch_all', 
          :constraints => { :id => /\d+/ }, 
          :resource => resource_name,
          :as => resource_name,
          :defaults => { :format => 'json' })
    
    match("#{model.toast_config.namespace}/#{resource_name}/:subresource" => 'toast#catch_all', 
          :resource => resource_name,
          :defaults => { :format => 'json' })
  end

end



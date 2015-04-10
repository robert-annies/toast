Rails.application.routes.draw do

  ActiveRecord::Base.descendants.each do |model|
    next unless model.is_resourceful_model?

    resource_name = model.to_s.pluralize.underscore

    namespaces = []

    # routes must be defined for all defined namespaces of a model
    model.toast_configs.each do |tc|
      # once per namespace
      next if namespaces.include? tc.namespace

      namespaces << tc.namespace

      match("#{tc.namespace}/#{resource_name}(/:id(/:subresource))" => 'toast#catch_all',
            :via         => [:get, :post, :put, :delete],
            :constraints => { :id => /\d+/ },
            :resource    => resource_name,
            :as          => resource_name,
            :defaults    => { :format => 'json' })

      match("#{tc.namespace}/#{resource_name}/:subresource" => 'toast#catch_all',
            :via         => [:get, :post, :put, :delete],
            :resource    => resource_name,
            :defaults    => { :format => 'json' })
    end
  end

end

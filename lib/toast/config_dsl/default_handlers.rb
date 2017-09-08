module Toast::ConfigDSL::DefaultHandlers
  def plural_assoc_get_handler assoc_name
    lambda do |source, uri_params|
      source.send(assoc_name)
    end
  end

  def singular_assoc_get_handler assoc_name
    lambda do |source, uri_params|
      source.send(assoc_name)
    end
  end

  def single_get_handler model_class, single_name
    lambda do |uri_params|
      model_class.send(single_name)
    end
  end

  def collection_get_handler model_class, coll_name
    lambda do |uri_params|
      model_class.send(coll_name)
    end
  end

  def canonical_get_handler
    lambda do |model, uri_params|
      model
    end
  end

  def canonical_patch_handler
    lambda do |model, payload, uri_params|
      model.update payload
    end
  end

  def collection_post_handler model_class
    lambda do |payload, uri_params|
      model_class.create payload
    end
  end

  def plural_assoc_post_handler assoc_name
    lambda do |source, payload, uri_params|
      source.send(assoc_name).create payload
    end
  end

  def canonical_delete_handler
    lambda do |model, uri_params|
      model.destroy
    end
  end

  def singular_assoc_link_handler assoc_name
    lambda do |source, target, uri_params|
      source.send("#{assoc_name}=", target)
      source.save
    end
  end

  def plural_assoc_link_handler assoc_name
    lambda do |source, target, uri_params|
      source.send(assoc_name) << target
    end
  end

  def singular_assoc_unlink_handler assoc_name
    lambda do |source, target, uri_params|
      if source.send(assoc_name) == target
        source.send("#{assoc_name}=", nil)
        source.save
      end
    end
  end

  def plural_assoc_unlink_handler name
    lambda do |source, target, uri_params|
      source.send(name).delete(target)
    end
  end
end

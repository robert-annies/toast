module Toast::ConfigDSL::DefaultHandlers
  def plural_assoc_get_handler name
    lambda do |relation, uri_params|
      relation
    end
  end

  def singular_assoc_get_handler name
    eval "lambda do |source, uri_params|
            source.#{name}
          end"
  end

  def single_get_handler name
    eval "lambda do |source, uri_params|
            source.#{name}
          end"
  end

  def collection_get_handler model, name
    eval "lambda do |uri_params|
            #{model}.#{name}
          end"
  end

  def canonical_get_handler
    lambda do |model_instance, uri_params|
      model_instance
    end
  end

  def canonical_put_handler
    lambda do |model_instance, payload, uri_params|
      model_instance.update! payload
    end
  end

  def collection_post_handler model
    eval "lambda do |payload, uri_params|
            #{model}.create! payload
          end"
  end

  def plural_assoc_post_handler name
    eval "lambda do |source, payload, uri_params|
            source.#{name}.create! payload
          end"
  end

  def canonical_delete_handler
    lambda do |model_instance, uri_params|
      model_instance.destroy!
    end
  end

  def singular_assoc_link_handler name
    eval "lambda do |source, target, uri_params|
            source.#{name} = target
            source.save!
          end"
  end

  def plural_assoc_link_handler name
    eval "lambda do |source, target, uri_params|
            source.#{name} << target
          end"
  end

  def singular_assoc_unlink_handler name
    eval "lambda do |source, target, uri_params|
            if source.name == target
              source.#{name} = nil
              source.save!
            end
          end"
  end

  def plural_assoc_unlink_handler name
    eval "lambda do |source, target, uri_params|
            source.#{name}.delete(target)
          end"
  end
end

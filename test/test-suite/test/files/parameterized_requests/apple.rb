expose(Apple, as: 'application/apple+json') {
  writables   :name, :number

  via_get {
    allow do |*args|
      true
    end

    handler do |model_instance, uri_params|
      model_instance.send(uri_params[:filter]+'=', '[FILTERED]')
      model_instance
    end
  }

  via_patch {
    allow do |role, apple, uri_params|
      raise 'Boom!' if uri_params.key? 'allow_bomb'
      true
    end

    handler do |model_instance, payload, uri_params|
      raise 'Boom!' if uri_params.key? 'handler_bomb'
      bad_request 'Poing!' if uri_params.key? 'handler_bomb_badreq'

      model_instance.update! payload

      if uri_params.key? 'remember_value'
        model_instance.previous_changes.each do |attr, change|
          if model_instance.has_attribute? attr+'_history'
            model_instance.update_attribute(attr+'_history',
                                            model_instance.read_attribute(attr+'_history') << change.first)
          end
        end
      end
    end
  }

  via_delete {
    allow do |role, apple, uri_params|
      raise 'Boom!' if uri_params.key? 'allow_bomb'
      true
    end

    handler do |model_instance, uri_params|
      raise 'Boom!' if uri_params.key? 'handler_bomb'
      model_instance.destroy!
      if uri_params.key? 'log'
        Rails.logger.info "#{model_instance} was deleted"
      end
      model_instance
    end
  }

  single(:pluck) {
    via_get {
      allow do |role, apple, uri_params|
        raise 'A momentary lapse of reason' if uri_params[:num_equals] == '666'
        role == :admin
      end

      handler do |uri_params|
        Apple.find_by_number uri_params[:num_equals]
      end
    }
  }

  single(:steal) {
    # empty
  }

  association(:bananas, :as => 'application/bananas+json') {
    max_window 100
    via_get {
      allow do |auth, apple, uri_params|
        if uri_params.key? 'allow_bomb'
          raise "Boom!"
        end
        true
      end

      handler do |source, uri_params|
        source.bananas.order(uri_params[:sort_by])
      end
    }

    via_post {
      allow do |auth, apple, uri_params|
        raise 'Boom!' if uri_params.key? 'allow_bomb'
        true
      end

      handler do |source, payload, uri_params|
        source.bananas.create! payload do |banana|
          raise 'Boom!' if uri_params.key? 'handler_bomb'
          if uri_params[:set_curvature].to_i < 330
            banana.curvature =  uri_params[:set_curvature].to_i
          end
        end
      end
    }

    via_link {
      allow do |auth, apple, uri_params|
        raise 'Boom!'  if uri_params.key? 'allow_bomb'
        true
      end

      handler do |source, target, uri_params|
        raise 'Boom!' if uri_params.key? 'handler_bomb'
        target.name += uri_params[:append_to_name]
        target.save
        source.bananas << target
      end
    }
    via_unlink {
      allow do |auth, apple, uri_params|
        raise 'Boom!'  if uri_params.key? 'allow_bomb'
        true
      end

      handler do |source, target, uri_params|
        raise 'Boom!' if uri_params.key? 'handler_bomb'

        if  uri_params.key? 'mark_removed'
          target.update_attribute :name, target.name+' (removed)'
        end
        source.bananas.delete(target)
      end
    }
  }

  collection(:all, :as => 'application/apples+json') {
    via_get {
      allow do |auth, req_model, uri_params|
        uri_params[:less_than].to_i > 12 or  uri_params[:less_than].to_i == 0
      end

      handler do |uri_params|
        Apple.where("number < #{uri_params[:less_than]}")
      end
    }

    via_post {
      allow do |*args|
        true
      end

      handler do |payload, uri_params|
        Apple.create! payload do |a|
          if uri_params[:with] == 'bomb'
            raise 'Boom!'
          end
          if uri_params[:with] == 'banana'
            a.bananas << Banana.create!(:name => 'Ullamcorper Nibh Sollicitudin', :number => 104)
          end
        end
      end
    }
  }
}

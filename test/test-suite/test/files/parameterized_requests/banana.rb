expose(Banana, as: 'application/banana+json', under: 'test/api-v1/') {

  writables :name, :number
  readables :curvature

  single(:first) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  association(:apple, as: 'application/apple+json')  {
    via_get {
      allow do |*args|
        true
      end

      handler do |banana, uri_params|
        if uri_params[:secret] == 'hellodoggy'
          raise 'Wuff!'
        end

        unless  uri_params[:secret] == 'hellokitty'
          banana.apple.name = '[FILTERED]'
        end
        banana.apple
      end
    }

    via_link {
      allow do |*args|
        true
      end

      handler do |source, target, uri_params|

        if uri_params.keys.include? 'bomb'
          raise "Boom!"
        end

        unless uri_params[:keep_existing] == 'true' and source.apple
          source.apple = target
          source.save!
        end
      end
    }

    via_unlink {
      allow do |auth, banana, uri_params|
        if uri_params.keys.include? 'bomb_for_allow'
          raise "Boom!"
        end
        true
      end

      handler do |source, target, uri_params|
        if uri_params[:doit] == 'yes'
          source.apple = nil
          source.save!
        elsif uri_params[:doit] == 'no'
          # nop
        else
          raise 'Say yes or no'
        end
      end
    }
  }

  collection(:query) {
    max_window 99
    via_get {
      allow do |*args|
        true
      end
      handler do |uri_params|
        Banana.query(uri_params[:gt])
      end
    }
  }

  collection(:all) {
    via_get {
      allow do |*args|
        true
      end
    }
  }

  collection(:less_than_hundred) {
    via_get {
      allow do |*args|
        true
      end
    }
  }
}

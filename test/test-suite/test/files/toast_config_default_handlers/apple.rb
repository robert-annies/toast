expose(Apple, as: 'application/apple+json') {
  writables   :name, :number
  readables   :kind

  via_get {
    allow do |*args|
      true
    end
  }

  via_patch {
    allow do |role, apple, uri_params|
      role == :admin
    end
  }

  via_delete {
    allow do |role, apple, uri_params|
      role == :admin
    end
  }

  single(:first) {
    via_get {
      allow do |role, apple, uri_params|
        role == :admin
      end
    }
  }

  association(:bananas_surprise, :as => 'application/bananas+json') {
    via_get {
      allow do |*args|
        true
      end

      handler do |source, uri_params|
        Time.now
      end
    }
  }

  association(:bananas, :as => 'application/bananas+json') {

    via_get {
      allow do |role, bananas, uri_params|
        role == :admin
      end
    }

    via_post {
      allow do |role, bananas, uri_params|
        role == :admin
      end
    }

    via_link {
      allow do |role, bananas, uri_param|
        role == :admin
      end
    }

    via_unlink {
      allow do |role, bananas, uri_param|
        role == :admin
      end
    }
  }

  collection(:all, :as => 'application/apples+json') {
    max_window = :unlimited
    
    via_get {      
      allow do |role, relation, uri_params|
        role == :admin
      end
    }

    via_post {
      allow do |role, relation, uri_params|
        role == :admin
      end
    }
  }
}

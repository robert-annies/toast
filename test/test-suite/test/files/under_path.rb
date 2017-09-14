expose(Dragonfruit, under: '/api/v1') {
  via_get{ 
    allow do |*args|
      true
    end
  }
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}

expose(Banana, under: '/api/v1') {
  via_get{ 
    allow do |*args|
      true
    end
  }
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}

expose(Coconut, under: '/api/v2') {
  via_get{ 
    allow do |*args|
      true
    end
  }
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
  association(:banana) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}

expose(Eggplant) {
  via_get{ 
    allow do |*args|
      true
    end
  }
  association(:apples) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}

expose(Apple, under: '/fruits') { 
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}
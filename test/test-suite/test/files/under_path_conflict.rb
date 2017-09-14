expose(Dragonfruit, under: '/api/v1') {
  via_get{ 
    allow do |*args|
      true
    end
  }
}

expose(Banana, under: '/api/v1') {
  via_get{ 
    allow do |*args|
      true
    end
  }
}

expose(Coconut, under: '/api/v2') {
  via_get{ 
    allow do |*args|
      true
    end
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
}

# ambiguous prefix: GET /eggplants/5/apples
# could be apples association of Eggplant#5 or all collection of Apple
# should be a config error
expose(Apple, under: '/eggplants/5') { 
  collection(:all) {
    via_get{ 
      allow do |*args|
        true
      end
    }
  }
}
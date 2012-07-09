module Toast
  class ScopedAssociation < Resource
    # delegeates everything to Toast::Collection, where the model is replaced
    # by the Relation this association creates 

    def initialize(model, id, association_name, scope_name,  params, 
                   config_in, config_out)
                   
      record = model.find(id)
      assoc_model = record.class
      
      @collection = Toast::Collection.new(record.send(association_name), 
                                          scope_name,
                                          params,
                                          config_in,
                                          config_out)

    end

    delegate :get, :put, :post, :delete, :base_uri, :base_uri=, :to => :@collection

  end
end

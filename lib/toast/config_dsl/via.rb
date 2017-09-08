class Toast::ConfigDSL::ViaVerb
  def initialize config_data
    @config_data = config_data
    @config_data.permissions = []
  end

  def allow &block
    # checks...
    @config_data.permissions << block
  end
end

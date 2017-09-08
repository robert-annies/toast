module Toast::ConfigDSL::Common
  def initialize config_data=nil
    @config_data = config_data
  end

  def method_missing method, *args
    raise_config_error "Unknown directive: `#{method}'"
  end

  def check_symbol_list list
    unless list.is_a?(Array) and list.all?{|x| x.is_a? Symbol}
      raise_config_error "Directive requires a list of symbols.\n"+
                         "  #{list.map{|x| x.inspect}.join(', ')} ?"
    end
  end

  def raise_config_error message=''
    match = caller.grep(/#{Toast::ConfigDSL.cfg_name}/).first

    file_line = if match.nil?
                  Toast::ConfigDSL.cfg_name
                else
                  match.split(':in').first
                end

    message += "\n              directive: /#{Toast::ConfigDSL.stack.join('/')}"
    message += "\n              in file  : #{file_line}"

    Toast.raise_config_error message
  end

  # ... to not forget to pop use:
  def stack_push level, &block
    Toast::ConfigDSL.stack << level
    yield
    Toast::ConfigDSL.stack.pop
  end
end

class Toast::ConfigDSL::ViaVerb
  include Toast::ConfigDSL::Common

  def allow &block
    stack_push 'allow' do

      unless block.arity.in? [3, -2, -1]
        raise_config_error 'Allow rule must list arguments as |*all|, |auth, *rest| or |auth, request_model, uri_params|'
      end

      @config_data.permissions << block
    end
  end

  def handler &block
    stack_push 'handler' do

      # arity check for custom handlers
      expected_arity = case Toast::ConfigDSL.stack[-3]
                       when /\Asingle/
                         1
                       when /\Acollection/
                         case Toast::ConfigDSL.stack[-2]
                         when 'via_get'  then 1
                         when 'via_post' then 2
                         end

                       when /\Aassociation/
                         case Toast::ConfigDSL.stack[-2]
                         when 'via_get'                    then 2
                         when /\Avia_(post|link|unlink)\z/ then 3
                         end

                       when /\Aexpose/
                         case Toast::ConfigDSL.stack[-2]
                         when /\Avia_(get|delete)\z/ then 2
                         when 'via_patch'              then 3
                         end
                       end


      if block.arity != expected_arity
        raise_config_error "Handler block must take exactly #{expected_arity} argument#{expected_arity==1?'':'s'}"
      end

      @config_data.handler = block
    end
  end
end

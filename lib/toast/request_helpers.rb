require 'toast/errors'

module Toast::RequestHelpers

  def get_config model_class
    Toast.expositions.detect do |exp|
      exp.model_class == model_class
    end || raise(Toast::Errors::ConfigNotFound)
  end

  def base_uri request
    Toast.base_uri
  end

  # split the name and id of the resource from a LinkHeader
  def split_link_header link
    URI(link.href).path.sub(@request.script_name,'').split('/')[1..-1]
  end

  def represent_one record, config
    result = {}

    model_uri = [@base_uri, config.prefix_path, record.class.name.underscore.pluralize].delete_if(&:blank?).join('/')

    # can we inject model_uri  into the recortd, so that virtual attribute methods can use it in their result?

    # - setting a special property on the record :-/, OK Toast could extend all exposed classes by a special accessor,
    #   maybe only if configured.
    # - calling somehow this method in different/extended context (how?)
    # - passing this as parameter, while not requiring all the attribute methods to accept a 2. arg (possible?)
    # - If the result is a String it can return a templated String like "{{ toast_uri }}", OK for single
    #   strings, but for mebedded Hashes with Strings no, too expensive.

    (config.readables + config.writables).each do |attr|
      result[attr.to_s] = record.send(attr) if attr_selected?(attr)
    end

    result['self'] = "#{model_uri}/#{record.id}" if attr_selected?('self')

    # add associations, collections and singles
    config.associations.each do |name, config|
      result[name.to_s] = "#{model_uri}/#{record.id}/#{name}" if attr_selected?(name)
    end

    config.singles.each do |name, config|
      result[name.to_s] = "#{model_uri}/#{name}" if attr_selected?(name)
    end

    config.collections.each do |name, config|
      if attr_selected?(name)
        result[name.to_s] = if name == :all
                         "#{model_uri}"
                       else
                         "#{model_uri}/#{name}"
                       end
      end
    end

    result
  end

  def represent one_or_many_records, config

    result = if one_or_many_records.respond_to?(:map)
               one_or_many_records.map do |record|
                 represent_one(record, config)
               end
             else
               represent_one(one_or_many_records, config)
             end

    result.to_json
  end

  def allowed_methods(config)
    ["DELETE", "GET", "LINK", "PATCH", "POST", "UNLINK"].select{|m|
      !config.send("via_#{m.downcase}").nil?
    }.join(", ")
  end

  # Builds a Rack conform response tripel. Should be called at the end of the
  # request processing.
  #
  # Params:
  # - status_sym [Symbol] A status code name like :ok, :unauthorized, etc.
  # - headers:   [Hash]   HTTP headers, defaults to empty Hash
  # - msg:       [String] A Message for Toast log file, will be included in the body,
  #                       if body is no set and app is in non-production modes
  # - body:      [String] The repsosne body text, default to nil
  #
  # Return: Rack conform response
  def response status_sym, headers: {}, msg: nil, body: nil
    Toast.logger.info "done: #{msg}"

    unless Rails.env == 'production'
      # put message in body, too, if body is free
      body = msg if body.blank?
    end

    [ Rack::Utils::SYMBOL_TO_STATUS_CODE[status_sym],
      headers,
      [body] ]
  end

  def call_allow procs, *args
    procs.each do |proc|
      # call all procs, break if proc returns false and raise
      begin
        result = Object.new.instance_exec *args, &proc
      rescue => error
        raise Toast::Errors::AllowError.new(error, proc.source_location.join(':'))
      end

      if result == false
        raise Toast::Errors::NotAllowed.new(proc.source_location.join(':'))
      end
    end
  end

  def call_handler proc, *args
    result = nil

    begin
      context = Object.new
      context.define_singleton_method(:bad_request) do |message|
        raise Toast::Errors::BadRequest.new message, caller.first.sub(/:in.*/,'')
      end

      result = context.instance_exec *args, &proc

    rescue Toast::Errors::BadRequest
      raise # re-raise
    rescue => error
      raise Toast::Errors::HandlerError.new(error, error.backtrace.first.try(:sub,/:in.*/,''))
    end
    result
  end

  def is_active_record? klass
    klass.include? ActiveRecord::Core
  end

  def attr_selected? name
    (@selected_attributes.nil? or @selected_attributes.include?(name.to_s))
  end
end

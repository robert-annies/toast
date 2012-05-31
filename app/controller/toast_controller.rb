class ToastController < ApplicationController

  def catch_all

    begin

      @resource = Toast::Resource.build( params, request )

      render @resource.apply(request.method, request.body.read, request.content_type)

    rescue Toast::ResourceNotFound => e
      return head(:not_found)

    rescue Toast::PayloadInvalid => e
      return render :text => e.message, :status => :forbidden

    rescue Toast::PayloadFormatError => e
      return head(:bad_request)

    rescue Toast::MethodNotAllowed => e
      return head(:method_not_allowed)

    rescue Toast::UnsupportedMediaType => e
      return head(:unsupported_media_type)

    rescue Exception => e
      log_exception e
      raise e if Rails.env == "test"
      return head(:internal_server_error)
    end

  end

  def not_found
    return head(:not_found)
  end


  if Rails.env == "test"
    def log_exception e
      puts "#{e.class}: '#{e.message}'\n\n#{e.backtrace[0..14].join("\n")}\n\n"
    end
  else
    def log_exception e
      logger.error("#{e.class}: '#{e.message}'\n\n#{e.backtrace.join("\n")}")
    end
  end

end

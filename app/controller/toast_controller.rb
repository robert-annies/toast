require 'rack-link_headers'

class ToastController < ApplicationController

  def catch_all

    begin

      @resource = Toast::Resource.build( params, request )

      unless request.headers["LINK"].nil?
        # extract "path_info" from link header
        request.headers["LINK"] =~ /(#{request.protocol + request.host + request.script_name})(.*)/
      end

      toast_response = @resource.apply(request.method, request.body.read, request.content_type, $2)

      # pagination
      if pi = toast_response[:pagination_info]
        # URL w/o parameters

        url =  request.url.split('?').first
        qpar = request.query_parameters.clone

        # change/add page parameter
        link_header = []

        if pi[:prev]
          qpar[:page] = pi[:prev]
          response.link "#{url}?#{qpar.to_query}", :rel => :prev
        end

        if pi[:next]
          qpar[:page] = pi[:next]
          response.link "#{url}?#{qpar.to_query}", :rel => :next
        end

        qpar[:page] = pi[:last]
        response.link "#{url}?#{qpar.to_query}", :rel => :last

        qpar[:page] = 1
        response.link "#{url}?#{qpar.to_query}", :rel => :first

      end

      render toast_response

    rescue Toast::ResourceNotFound => e
      return head(:not_found)

    rescue Toast::PayloadInvalid => e
      return render :text => e.message, :status => :forbidden

    rescue Toast::PayloadFormatError => e
      return head(:bad_request)

    rescue Toast::BadRequest => e
      return head(:bad_request)

    rescue Toast::MethodNotAllowed => e
      return head(:method_not_allowed)

    rescue Toast::UnsupportedMediaType => e
      return head(:unsupported_media_type)

    rescue Toast::ResourceNotAcceptable => e
      return head(:not_acceptable)

    rescue Toast::Conflict => e
      return render :text => e.message, :status => :conflict

    rescue Exception => e
      log_exception e
      puts e if Rails.env == "test"
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

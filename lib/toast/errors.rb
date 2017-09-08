module Toast::Errors
  class ConfigNotFound < StandardError; end

  class HandlerError < StandardError
    attr_accessor :orig_error, :source_location

    def initialize orig_error, source_location
      @orig_error = orig_error
      @source_location = source_location
      super ''
    end
  end

  class AllowError < HandlerError; end

  class NotAllowed < StandardError
    attr_accessor :source_location

    def initialize source_location
      @source_location = source_location
      super ''
    end
  end

  class BadRequest < StandardError
    attr_accessor :source_location

    def initialize message, source_location
      @source_location = source_location
      super message
    end
  end

  class CustomAuthFailure < StandardError
    attr_accessor :response_data

    def initialize response_data
      @response_data = response_data
    end
  end
end
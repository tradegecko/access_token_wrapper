require "access_token_wrapper/version"

module AccessTokenWrapper
  class Base
    NON_ERROR_CODES = [402, 404, 422, 414, 429, 500, 503]
    attr_reader :raw_token

    def initialize(raw_token, &callback)
      @raw_token = raw_token
      @callback  = callback
    end

    def method_missing(method, *args, &block)
      @raw_token.send(method, *args, &block)
    rescue OAuth2::Error => exception
      if NON_ERROR_CODES.include?(exception.response.status)
        raise exception
      else
        @raw_token = @raw_token.refresh!
        @callback.call(@raw_token, exception)
        @raw_token.send(method, *args, &block)
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @raw_token.respond_to?(method_name, include_private) || super
    end
  end
end

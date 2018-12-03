module AccessTokenWrapper
  class Base
    NON_ERROR_CODES = [402, 404, 422, 414, 429, 500, 503]
    EXPIRY_GRACE_SEC = 30
    attr_reader :raw_token

    def initialize(raw_token, reload_token: nil, &callback)
      @raw_token = raw_token
      @callback  = callback
      @reload_token = reload_token
    end

    def method_missing(method_name, *args, &block)
      reload_or_refresh_token! if token_expiring?
      @raw_token.send(method_name, *args, &block)
    rescue OAuth2::Error => exception
      if NON_ERROR_CODES.include?(exception.response.status)
        raise exception
      else
        reload_or_refresh_token!(exception)
        @raw_token.send(method_name, *args, &block)
      end
    end

    def reload_or_refresh_token!(exception = nil)
      if @reload_token
        @new_token = @reload_token.call
        if @new_token.token == @raw_token.token
          refresh_token!(exception)
        else
          @raw_token = @new_token
        end
      else
        refresh_token!(exception)
      end
    end

    def refresh_token!(exception)
      @raw_token = @raw_token.refresh!
      @callback.call(@raw_token, exception)
    end

    def token_expiring?
      @raw_token.expires_at && @raw_token.expires_at < (Time.now.to_i + EXPIRY_GRACE_SEC)
    end

    def respond_to_missing?(method_name, include_private = false)
      @raw_token.respond_to?(method_name, include_private) || super
    end
  end
end

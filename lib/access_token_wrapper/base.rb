module AccessTokenWrapper
  class Base
    NON_ERROR_CODES = [402, 404, 422, 414, 429, 500, 503]
    EXPIRY_GRACE_SEC = 30
    attr_reader :raw_token

    # This is the core functionality
    #
    # @example
    #   AccessTokenWrapper::Base.new(token) do |new_token, exception|
    #     update_user_from_access_token(new_token)
    #   end
    #
    # @param [<OAuth2::AccessToken] raw_token An instance of an OAuth2::AccessToken object
    # @param [&block] callback A callback that gets called when a token is refreshed,
    #  the callback is provided `new_token` and optional `exception` parameters
    #
    # @return <AccessTokenWrapper::Base>
    #
    # @api public
    def initialize(raw_token, &callback)
      @raw_token = raw_token
      @callback  = callback
    end

  private

    def method_missing(method_name, *args, &block)
      refresh_token! if token_expiring?
      @raw_token.send(method_name, *args, &block)
    rescue OAuth2::Error => exception
      if non_refreshable_exception?(exception)
        raise
      else
        refresh_token!(exception)
        @raw_token.send(method_name, *args, &block)
      end
    end

    def non_refreshable_exception?(exception)
      case exception.response.status
      when *NON_ERROR_CODES
        true
      when 400
        response.parsed['message'] == 'Duplicate Idempotency Key header detected'
      end
    end

    def refresh_token!(exception = nil)
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

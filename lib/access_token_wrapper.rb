require "access_token_wrapper/version"

module AccessTokenWrapper
  class Base
    attr_reader :token

    def initialize(token, &callback)
      @token    = token
      @callback = callback
    end

    def method_missing(method, *args, &block)
      token.send(method, *args, &block)
    rescue OAuth2::Error => exception
      @token = token.refresh!
      @callback.call(token)
      token.send(method, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      token.respond_to?(method_name, include_private) || super
    end
  end
end

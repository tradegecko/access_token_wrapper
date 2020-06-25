# frozen_string_literal: true

module AccessTokenWrapper
  class FromRecord < Base
    attr_reader :record

    # This is the core functionality
    #
    # @example
    #   AccessTokenWrapper::FromRecord.new(client: client, record: user) do |new_token, exception|
    #     update_user_from_access_token(new_token)
    #   end
    #
    # @param [<OAuth2::Client>] client An instance of an OAuth2::Client object
    # @param [<Object>] record An AR-like object that responds to `access_token`,
    #   `refresh_token`, `expires_at`, `with_lock` and `reload`.
    # @param [&block] callback A callback that gets called when a token is refreshed,
    #   the callback is provided `new_token` and optional `exception` parameters
    #
    # @return <AccessTokenWrapper::FromRecord>
    #
    # @api public
    def initialize(client:, record:, &callback)
      @oauth_client = client
      @record       = record
      super(build_token, &callback)
    end

  private

    # Override the refresh_token! method from the Base class to extend with locking logic
    def refresh_token!(exception = nil)
      @record.with_lock do
        fetch_fresh_record

        if token_requires_refresh?
          @raw_token = @raw_token.refresh!
          @callback.call(@raw_token, exception)
        end
      end
    end

    def build_token
      OAuth2::AccessToken.new(@oauth_client, record.access_token, {
        refresh_token: record.refresh_token,
        expires_at:    record.expires_at
      })
    end

    def fetch_fresh_record
      @last_token = @raw_token
      @record.reload
      @raw_token = build_token
    end

    def token_requires_refresh?
      @last_token.token == @raw_token.token
    end
  end
end

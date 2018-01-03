module AccessTokenWrapper
  class FromRecord < Base
    attr_reader :record

    # This is the core functionality
    #
    # @example
    #   AccessTokenWrapper::FromRecord.new(client: client, record: user, lock: :redis) do |new_token, exception|
    #     update_user_from_access_token(new_token)
    #   end
    #
    # @param [<OAuth2::Client>] client An instance of an OAuth2::Client object
    # @param [<Object>] record An object that responds to `access_token`,
    #   `refresh_token`, `expires_at`, `id` and `reload` (Likely an ActiveRecord model)
    # @param [#lock] lock Optional, if provided either the symbol `:redis` to use the
    #   built-in Redis lock or any other object that responds to a method named `lock`
    #   and takes block that yields.
    # @param [&block] callback A callback that gets called when a token is refreshed,
    #   the callback is provided `new_token` and optional `exception` parameters
    #
    # @return <AccessTokenWrapper::FromRecord>
    #
    # @api public
    def initialize(client:, record:, lock: nil, &callback)
      @oauth_client = client
      @record       = record
      @lock         = determine_lock(lock)
      super(build_token, &callback)
    end

  private

    # Override the refresh_token! method from the Base class to add all the extra functionality
    def refresh_token!(exception = nil)
      @lock.lock do
        fetch_fresh_record

        if !token_changed?
          @raw_token = @raw_token.refresh!
          # TODO: We may need this for https://github.com/doorkeeper-gem/doorkeeper/pull/769
          # @raw_token.get('/users/current')
        end
        @callback.call(@raw_token, exception)
      end
    end

    def build_token
      OAuth2::AccessToken.new(@oauth_client,  record.access_token, {
        refresh_token: record.refresh_token,
        expires_at:    record.expires_at
      })
    end

    def fetch_fresh_record
      @last_token = @raw_token
      @record.reload
      @raw_token  = build_token
    end

    def token_changed?
      @last_token.token != @raw_token.token
    end

    def determine_lock(lock)
      case lock
      when nil
        Passthrough
      when :redis
        require "access_token_wrapper/redis_lock"
        RedisLock.new([@record.class.to_s, @record.id].join("/"))
      else
        lock
      end
    end

    module Passthrough
      def self.lock
        yield
      end
    end
  end
end

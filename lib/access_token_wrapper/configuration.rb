# frozen_string_literal: true

module AccessTokenWrapper
  #  Global configuration object
  #
  #  AccessTokenWrapper.configure do |config|
  #    config.skip_statuses << 520
  #    config.skip_refresh do |response|
  #      response.parsed['message'] == 'Duplicate Idempotency Key header detected'
  #    end
  #  end
  class Configuration
    attr_accessor :skip_statuses, :skip_refresh_block

    def initialize
      @skip_statuses = [402, 404, 414, 422, 429, 500, 503]
      @skip_refresh_block = ->(_response) { false }
    end

    def skip_refresh(&block)
      @skip_refresh_block = block
    end
  end
end

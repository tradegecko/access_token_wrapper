# frozen_string_literal: true

require "access_token_wrapper/base"
require "access_token_wrapper/from_record"
require "access_token_wrapper/configuration"

module AccessTokenWrapper
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require 'test_helper'

class AccessTokenWrapperTest < Minitest::Test
  class FakeToken
    attr_reader :refreshed

    def initialize(options = {})
      @has_run = nil
      @options = options
    end

    def get(*)
      ""
    end

    def expires_at
      @options[:expires_at] || Time.now.to_i + 3600
    end

    def get_and_raise(code)
      if @has_run
        ""
      else
        @has_run = true
        raise OAuth2::Error, OpenStruct.new(status: code, parsed: { 'error' => code }, body: '')
      end
    end

    def refresh!
      @refreshed = true
      self
    end
  end

  def described_class
    AccessTokenWrapper::Base
  end

  def test_doesnt_run_block_if_no_exception
    @run = false

    token = described_class.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    token.get('/')
    assert !@run
    assert !token.refreshed
  end

  def test_runs_refresh_block_if_exception
    @run = false

    token = described_class.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    token.get_and_raise(401)
    assert @run
    assert token.refreshed
  end

  def test_runs_refresh_block_if_expiring
    @run = false

    token = described_class.new(FakeToken.new(expires_at: Time.now.to_i - 1)) do |new_token, exception|
      @run = true
    end

    token.get('/')
    assert @run
    assert token.refreshed
  end

  def test_doesnt_run_block_if_non_auth_exception
    @run = false

    token = described_class.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    begin
      token.get_and_raise(429)
    rescue OAuth2::Error
    end

    assert !@run
    assert !token.refreshed
  end

  def test_doesnt_run_refresh_block_with_skip_block
    AccessTokenWrapper.configure do |config|
      config.skip_refresh do |response|
        true
      end
    end

    @run = false

    token = described_class.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    begin
      token.get_and_raise(401)
    rescue OAuth2::Error
    end

    assert !@run
    assert !token.refreshed
  ensure
    AccessTokenWrapper.reset_configuration!
  end
end

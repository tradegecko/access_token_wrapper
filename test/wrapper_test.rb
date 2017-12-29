require 'minitest/autorun'
require 'access_token_wrapper'
require 'oauth2'

class AccessTokenWrapperTest < Minitest::Test
  class FakeToken
    attr_reader :refreshed

    def initialize
      @has_run = nil
    end

    def get(*)
      ""
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

  def client
    @client ||= OAuth2::Client.new('AAA', 'BBB')
  end

  def test_doesnt_run_block_if_no_exception
    @run = false

    token = AccessTokenWrapper::Base.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    token.get('/')
    assert !@run
    assert !token.refreshed
  end

  def test_runs_refresh_block_if_exception
    @run = false

    token = AccessTokenWrapper::Base.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    token.get_and_raise(401)
    assert @run
    assert token.refreshed
  end

  def test_doesnt_run_block_if_non_auth_exception
    @run = false

    token = AccessTokenWrapper::Base.new(FakeToken.new) do |new_token, exception|
      @run = true
    end

    begin
      token.get_and_raise(429)
    rescue OAuth2::Error
    end

    assert !@run
    assert !token.refreshed
  end
end

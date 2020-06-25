require 'test_helper'

class FromRecordTest < Minitest::Test
  def described_class
    AccessTokenWrapper::FromRecord
  end

  class FakeRecord
    class << self
      attr_accessor :locked
    end

    attr_reader :id, :reloaded
    attr_accessor :access_token, :refresh_token, :expires_at
    attr_writer :fresh_token

    def initialize(access_token: 'ABC', refresh_token: 'DEF', expires_at: Time.now.to_i + 3600)
      update_from_access_token(OpenStruct.new(token: access_token, refresh_token: refresh_token, expires_at: expires_at))
      @id = 42
      @fresh_token = nil
    end

    def update_from_access_token(token)
      @access_token = token.token
      @refresh_token = token.refresh_token
      @expires_at = token.expires_at
    end

    def reload
      @reloaded = true
      if @fresh_token
        update_from_access_token(@fresh_token)
        @fresh_token = nil
      end
    end

    def with_lock
      true while self.class.locked

      self.class.locked = true
      sleep 0.1
      yield
      self.class.locked = false
    end
  end

  class ExpiringFakeRecord < FakeRecord
    def reload
      @access_token  = access_token  + "*"
      @refresh_token = refresh_token + "*"
      @expires_at    = Time.now.to_i + 3600
      super
    end
  end

  def client
    @client ||= OAuth2::Client.new('AAA', 'BBB', site: 'http://localhost:3000')
  end

  def setup
    stub_request(:get, "http://localhost:3000/200").to_return(status: 200, body: "")
    stub_request(:get, "http://localhost:3000/401").to_return({ status: 401, body: "" }, { status: 200, body: "" })
    stub_request(:get, "http://localhost:3000/429").to_return(status: 429, body: "")
  end

  def stub_token_refresh
    stub_request(:post, "http://localhost:3000/oauth/token").with(body: {"client_id"=>"AAA", "client_secret"=>"BBB", "grant_type"=>"refresh_token", "refresh_token"=>"DEF"}).to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: token_response.to_json).times(1)
  end

  def stub_token_refresh_with_wait
    stub_request(:post, "http://localhost:3000/oauth/token").to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: lambda { |request| sleep 0.1; token_response.to_json }).times(1)
  end

  def token_response
    {
      "access_token": "57ed301af04bf35b40f255feb5ef469ab2f046aff14",
      "expires_in": 7200,
      "refresh_token": "026b343de07818b3ffebfb3001eff9a00aea43da0 ",
      "scope": "public",
      "token_type": "bearer"
    }
  end

  def test_doesnt_run_block_if_no_exception
    @run = false

    token = described_class.new(client: client, record: FakeRecord.new) do |new_token, exception|
      @run = true
    end

    token.get('/200')
    assert !@run
    assert !token.record.reloaded
  end

  def test_runs_refresh_block_if_exception
    @run = false
    stub_refresh = stub_token_refresh

    token = described_class.new(client: client, record: FakeRecord.new) do |new_token, exception|
      @run = true
    end

    token.get('/401')
    assert @run
    assert token.record.reloaded
    assert_requested(stub_refresh)
  end

  def test_runs_refresh_block_if_expiring
    @run = false
    stub_refresh = stub_token_refresh
    token = described_class.new(client: client, record: FakeRecord.new(expires_at: Time.now.to_i - 1)) do |new_token, exception|
      @run = true
    end

    token.get('/200')
    assert @run
    assert token.record.reloaded
    assert_requested(stub_refresh)
  end

  def test_doesnt_run_block_if_non_auth_exception
    @run = false

    token = described_class.new(client: client, record: FakeRecord.new) do |new_token, exception|
      @run = true
    end

    begin
      token.get('/429')
    rescue OAuth2::Error
    end

    assert !@run
    assert !token.record.reloaded
  end

  def test_refreshes_record_and_halts_api_request_if_not_needed
    @run = false
    stub_refresh = stub_token_refresh

    token = described_class.new(client: client, record: ExpiringFakeRecord.new) do |new_token, exception|
      @run = true
    end

    token.get('/401')

    assert !@run
    assert_not_requested(stub_refresh)
    assert token.record.reloaded
  end

  def test_that_the_lock_locks_multiple_requests
    @results = []
    record      = FakeRecord.new(expires_at: Time.now.to_i-1)
    record_copy = FakeRecord.new(expires_at: Time.now.to_i-1)

    token = described_class.new(client: client, record: record) do |new_token, exception|
      record.update_from_access_token(new_token)
      record_copy.fresh_token = new_token
      @run = true
    end

    token2 = described_class.new(client: client, record: record_copy) do |new_token, exception|
      @run = true
    end

    stub_refresh = stub_token_refresh_with_wait

    new_thread = Thread.new do
      @results << :before_primary
      token.get('/200')
      @results << :after_primary
    end

    sleep 0.01

    @results << :before_secondary
    token2.get('/200')
    @results << :after_secondary

    new_thread.join
    assert_equal [:before_primary, :before_secondary, :after_primary, :after_secondary], @results
    assert_requested(stub_refresh)
  end
end

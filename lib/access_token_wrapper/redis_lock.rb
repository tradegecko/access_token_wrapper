require 'redis'
class RedisLock
  class MultipleAccessError < StandardError; end
  EXPIRE_AFTER_SECONDS = 35
  RETRY_COUNT = 10
  WAIT_INTERVAL_MS = 500
  UNLOCK_SCRIPT='
  if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
  else
    return 0
  end'

  def initialize(key, expiry: EXPIRE_AFTER_SECONDS, redis_client: Redis.current, retry_count: RETRY_COUNT, wait_interval_ms: WAIT_INTERVAL_MS)
    @key    = "redis-lock-#{key}"
    @redis  = redis_client
    @expiry = expiry
    @wait_interval = wait_interval_ms / 1000.0
    @retry_count   = retry_count
  end

  def lock(&block)
    begin
      retries ||= 0
      single_lock(&block)
    rescue MultipleAccessError
      if (retries += 1) < @retry_count
        sleep @wait_interval
        retry
      else
        raise
      end
    end
  end

  def single_lock
    lock_id = SecureRandom.base64(20)

    if lock_mutex(@key, lock_id)
      begin
        yield
      ensure
        unlock_mutex(@key, lock_id)
      end
    else
      raise MultipleAccessError
    end
  end

  def lock_mutex(key, lock_id)
    @redis.set(key, lock_id, nx: true, ex: @expiry)
  end

  def unlock_mutex(key, lock_id)
    @redis.eval(UNLOCK_SCRIPT, [key], [lock_id])
  end
end

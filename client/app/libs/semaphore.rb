require 'memcache'

class Semaphore
  def initialize
    @mem = MemCache.new Rails.application.config.memcache_host + ":11211"
    @key = "sem"
  end

  def acquire()
    if @mem[@key].nil?
      @mem[@key] = 1
    end
    while true do
      if @mem[@key] > 0
        @mem[@key] -= 1
        break
      end
      Rails.logger.info("wait for unlock")
      sleep(30)
    end
  end

  def release()
    @mem[@key] += 1
  end
end
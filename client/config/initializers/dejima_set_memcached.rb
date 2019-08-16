Rails.application.configure do
  config.memcache_host = ENV["MEMCACHE_HOST"]
end

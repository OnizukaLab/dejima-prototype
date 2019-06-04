Rails.application.configure do
  if config.prototype_role == :peer
    config.dejima_peer_type = (ENV["PEER_TYPE"] || "government").to_sym
    config.peer_network_address = ENV["PEER_NETWORK_ADDRESS"]
  elsif config.prototype_role == :client
    config.memcache_host = ENV["MEMCACHE_HOST"]
  end

end
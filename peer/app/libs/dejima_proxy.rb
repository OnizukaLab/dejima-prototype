require 'set'
require 'rest-client'

module DejimaProxy
  def self.send_peer_group_request(peer, peer_groups)
    Rails.logger.info("Sending peer group request.\n Peer: #{peer}\n Payload: #{peer_groups}")
    begin
      RestClient::Request.execute(method: :get, url: "#{peer}:3000/hello",
                                  timeout: 10) # quick check for unresponsive peer
      response = RestClient.post("#{peer}:3000/dejima/detect", peer_groups: peer_groups.to_json)
      Rails.logger.info "Peer #{peer} responded: #{response}"
      JSON.parse(response.body, symbolize_names: true).map(&PeerGroup.method(:new))
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.warn "RestClient error for peer #{peer}: #{e}"
      "connection_error"
    rescue SocketError => e
      Rails.logger.warn "Couldn't open socket to peer #{peer}: #{e}"
      "connection_error"
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn "Connection to peer #{peer} refused: #{e}"
      "connection_error"
    end
  end

  def self.send_update_dejima_table(payload)
    view_name = payload[:view].split('.')[1]
    table = DejimaTable.get_dejima_table_by_view(view_name)
    peers = PeerGroups.get[table].peers - [Rails.application.config.peer_network_address].to_set

    Rails.logger.info "send update dejima table to: " + peers.to_s
    Rails.logger.info("Sending updates for remote dejima tables.\n Peers: #{peers}\n Payload: #{payload}")
    responses = {}
    peers.each do |peer|
      response = RestClient.post(
        "#{peer}:3000/dejima/update_dejima_table",
        JSON.generate(payload),
        content_type: :json,
        accept: :json
      )
      Rails.logger.info "Peer #{peer} responded: #{response}"
      responses[peer] = JSON.parse response.body
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.warn "RestClient error for peer #{peer}: #{e}"
    rescue SocketError => e
      Rails.logger.warn "Couldn't open socket to peer #{peer}: #{e}"
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn "Connection to peer #{peer} refused: #{e}"
    end
    responses
  end

  def self.check_update_dejima_table(view)
    view_name = view.split('.')[1]
    ActiveRecord::Base.connection.execute("SELECT non_trigger_#{view_name}_detect_update();\n")
    Rails.logger.info("check_update_dejima_table(#{view_name}) is executed.")
    return 
  end
end

# detecting from bank to government
# request: { values: [:first_name, :last_name, :address, :phone], peers: ['government', 'bank']}

# response: [{ values: [:first_name, :last_name, :address], peers: ['government', 'bank', 'insurance']},
#           { values: [:phone], peers: ['government', 'bank']}]

# detecting from goverment to bank
# request1: { values: [:first_name, :last_name, :address], peers: ['government', 'bank', 'insurance']}
# request2: { values: [:phone], peers: ['government', 'bank']}

require 'set'
require 'rest-client'

module DejimaProxy

    # call detect method for given peers
    def self.send_peer_group_request(peers, payload)
        Rails.logger.info("\e[31m" + __method__.to_s + " is called\e[0m")


        Rails.logger.info("Sending peer group request.\n Peers: #{peers}\n Payload: #{payload}")
        responses = {}
        peers.each do |peer|
            begin
                RestClient::Request.execute(method: :get, url: "#{peer}:3000/hello",
                    timeout: 5) # quick check for unresponsive peer
                response = RestClient.post("#{peer}:3000/dejima/detect", payload)
                Rails.logger.info "Peer #{peer} responded: #{response}"
                responses[peer] = JSON.parse response.body
            rescue RestClient::ExceptionWithResponse => e
                Rails.logger.warn "RestClient error for peer #{peer}: #{e}"
                responses[peer] = "connection_error"
            rescue SocketError => e
                Rails.logger.warn "Couldn't open socket to peer #{peer}: #{e}"
                responses[peer] = "connection_error"
            rescue Errno::ECONNREFUSED => e
                Rails.logger.warn "Connection to peer #{peer} refused: #{e}"
                responses[peer] = "connection_error"
            end
        end
        responses
    end

    def self.send_update_dejima_table(payload)
        Rails.logger.info("\e[31m" + __method__.to_s + " is called\e[0m")

        peers = ["dejima-gov-peer.dejima-net"] #TODO yusuke ここで、決め打ちでgov-peer に飛ばしているが、これは動的に取得しないと行けないのでは？
        Rails.logger.info("Sending updates for remote dejima tables.\n Peers: #{peers}\n Payload: #{payload}")
        responses = {}
        peers.each do |peer|
            begin
                response = RestClient.post("#{peer}:3000/dejima/update_dejima_table", JSON.generate(payload), {content_type: :json, accept: :json})
                Rails.logger.info "Peer #{peer} responded: #{response}"
                responses[peer] = JSON.parse response.body
            rescue RestClient::ExceptionWithResponse => e
                Rails.logger.warn "RestClient error for peer #{peer}: #{e}"
            rescue SocketError => e
                Rails.logger.warn "Couldn't open socket to peer #{peer}: #{e}"
            rescue Errno::ECONNREFUSED => e
                Rails.logger.warn "Connection to peer #{peer} refused: #{e}"
            end
        end
        responses
    end
end


# detecting from bank to government
# request: { values: [:first_name, :last_name, :address, :phone], peers: ['government', 'bank']}

# response: [{ values: [:first_name, :last_name, :address], peers: ['government', 'bank', 'insurance']},
#           { values: [:phone], peers: ['government', 'bank']}]

# detecting from goverment to bank
# request1: { values: [:first_name, :last_name, :address], peers: ['government', 'bank', 'insurance']}
# request2: { values: [:phone], peers: ['government', 'bank']}

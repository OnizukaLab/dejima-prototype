module DejimaBase
  extend ActiveSupport::Concern

  included do
    self.dejima_tables = nil
  end

  class_methods do
    attr_accessor :dejima_tables

    def link_dejima_tables(views)
      self.dejima_tables = views
      Rails.logger.info "Linked dejima views on #{self} => #{views}"
    end

    # param: peer is host name of corresponding proxy server
    def create_peer_group(model)
      peer = application.config.peer_network_address
      begin
        RestClient::Request.execute(method: :get, url: "#{peer}:3000/hello",
                                    timeout: 10) # quick check for unresponsive peer
        response = RestClient.post("#{peer}:3000/dejima/create_peer_group", dejima_tables: dejima_tables.to_json)
        Rails.logger.info "Peer #{peer} responded: #{response}"
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
  end
end

require 'set'

class GovernmentUser < ApplicationRecord
  include DejimaBase
  # table columns
  # id, first_name, last_name, phone, address, birthdate

  # only peers link to other peers. client only manage local
  if Rails.application.config.prototype_role == :peer
    link_dejima_tables [{ table: ShareWithInsurance, peers: [Rails.application.config.peer_network_address, "dejima-insurance-peer.dejima-net"].to_set },
                        { table: ShareWithBank, peers: [Rails.application.config.peer_network_address, "dejima-bank-peer.dejima-net"].to_set }]
  end
end

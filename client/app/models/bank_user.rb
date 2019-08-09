require 'set'

class BankUser < ApplicationRecord
  include DejimaBase
  # table columns
  # id, first_name, last_name, phone, iban
#  def initialize
  link_dejima_tables [{ table: "ShareWithBank", peers: [Rails.application.config.peer_network_address, "dejima-gov-peer.dejima-net"].to_set }]
  binding.pry
  create_peer_groups [table_name]
#  end

end

module DejimaUtils
  # called by config/initializers/dejima_create_peer_groups.rb on startup
  def self.create_peer_groups(*models)
    # when creating we begin with all locally known peer groups
    PeerGroups.update check_local_peer_groups(models)
    Rails.logger.info "Peers groups: #{PeerGroups.get}"
    detect_peer_groups
  end

  # compares remote peer groups to the locally known peer groups
  # returns all local groups that have shared Dejima tables with a remote peer group,
  # i.e. the set intersection is not empty
  #
  # this is used for responding to peer detection requests
  # the requesting peer gets all groups relevant for him, because dependent Dejima tables
  # are either already in the same peer group or in another peer group, that is a super or subset.
  def self.compare_remote_peer_groups(remote_peer_groups)
    found_groups = Set.new
    remote_peer_groups.each do |remote_peer_group|
      PeerGroups.get.each_value do |peer_group|
        found_groups << peer_group if peer_group.dejima_tables.intersect? remote_peer_group.dejima_tables
      end
    end
    found_groups
  end

  # tries to detect other peer groups in the network based on the locally known peer groups
  def self.detect_peer_groups
    # now we start the network traversal
    peers_visited = Set.new([Rails.application.config.peer_network_address])
    loop do
      peers = {}

      # map peer addresses to peer_groups connected to this peer
      PeerGroups.get.each_value do |peer_group|
        peer_group.peers.each do |peer_address|
          peers[peer_address] ||= Set.new
          peers[peer_address] << peer_group
        end
      end

      peers_to_visit = Set.new(peers.keys) - peers_visited

      break if peers_to_visit.empty?

      peers_to_visit.each do |peer_address|
        peers_visited << peer_address
        response = DejimaProxy.send_peer_group_request(peer_address, peers[peer_address].to_a)
        next if response == "connection_error"

        response.each do |peer_group|
          PeerGroups.add_new_peer_group peer_group
        end
      end
    end

    # self.broadcast_peer_groups
  end

  # used to broadcast updated peer_groups to the whole network
  def self.broadcast_peer_groups(peer_groups)
    # TODO:
    # broadcast...
  end

  def self.check_local_peer_groups(models)
    attribute_to_dejima_tables = {}
    tables_to_peers = {}
    models.each do |model|
      # model.dejima_table example:
      # [{:table=>ShareWithInsurance, :peers=>#<Set: {"dejima-peer1.dejima-net", "dejima-peer3.dejima-net"}>},
      # {:table=>ShareWithBank, :peers=>#<Set: {"dejima-peer1.dejima-net", "dejima-peer2.dejima-net"}>}]
      model.dejima_tables.each do |dejima_table|
        dejima_table[:table].dejima_attributes.each do |attribute|
          attribute_to_dejima_tables[[model, attribute]] = Set.new unless attribute_to_dejima_tables[[model, attribute]]
          attribute_to_dejima_tables[[model, attribute]] << dejima_table[:table]
          tables_to_peers[dejima_table[:table]] = Set.new unless tables_to_peers[dejima_table]
          tables_to_peers[dejima_table[:table]] = tables_to_peers[dejima_table[:table]].union dejima_table[:peers]
        end
      end
    end

    # attribute_to_dejima_tables_map example:
    # {
    #   #<Set>[GovernmentUser,first_name]: [ShareWithInsurance, ShareWithBank],
    #   #<Set>[GovernmentUser,last_name]: [ShareWithInsurance, ShareWithBank],
    #   #<Set>[GovernmentUser,address]: [ShareWithInsurance, ShareWithBank],
    #   #<Set>[GovernmentUser,phone]: [ShareWithBank],
    #   #<Set>[GovernmentUser,birthdate]: [ShareWithInsurance]
    # }
    peer_groups = {}
    attribute_to_dejima_tables.each_pair do |attribute, dejima_tables|
      peer_group = peer_groups[dejima_tables] || PeerGroup.new(dejima_tables: dejima_tables)
      peer_group.attributes << attribute[1]
      dejima_tables.each do |dejima_table|
        peer_group.peers = peer_group.peers.union tables_to_peers[dejima_table]
      end
      peer_groups[dejima_tables] = peer_group
    end
    peer_groups
  end
end

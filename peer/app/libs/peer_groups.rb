module PeerGroups
  def self.get
    PeerGroupsStore.get.peer_groups
  end

  def self.update(peer_groups)
    pgs = PeerGroupsStore.get
    pgs.peer_groups = peer_groups
    pgs.save!
  end

  # This function adds new_group to the locally known peer_groups
  #
  # We need to detect all intersections between our known groups in peer_groups
  # and the new group that needs to be added to our peer groups
  #
  # In our existing peer_groups no peer_group shares any attributes with
  # another peer group, i.e. each attribute is exactly assigned to one peer group.
  #
  # For every intersection between dejima_tables of our peer groups and the new groups
  # we need to create or update the peer_group of the union of the dejima_tables with
  # the intersection of the attributes
  #
  # This might create new, larger peer groups and make existing groups obsolete.
  #
  # If new_group is disjoint to all local peer groups, it means this group has no
  # shared attributes and thus no relevance to this peer. It shouldn't have reached
  # this method in the first place.
  #
  # This algorithm could be optimized by removing handled attributes from new_group
  # on each iteration and breaking early once new_group.attributes is empty
  #
  def self.add_new_peer_group(new_group)
    peer_groups = PeerGroups.get
    peer_groups_clone = peer_groups.clone # clone, so we can change the peer_groups hash during iteration
    peer_groups_clone.each_value do |peer_group|
      next if peer_group.dejima_tables.disjoint? new_group.dejima_tables

      shared_attributes = peer_group.attributes.intersection new_group.attributes
      next if shared_attributes.empty?

      dejima_table_union = peer_group.dejima_tables.union new_group.dejima_tables
      if peer_groups[dejima_table_union]
        peer_groups[dejima_table_union].update_peers(new_group)
      else
        # create combined peer group, if it doesn't already exist
        combined_peer_group = PeerGroup.new(
          dejima_tables: dejima_table_union,
          attributes: shared_attributes,
          peers: (peer_group.peers.union new_group.peers)
        )
        peer_groups[dejima_table_union] = combined_peer_group
      end
      # remove attributes that moved to the new union group from existing group
      # unless the union group and existing group are identical
      next unless peer_group.dejima_tables != dejima_table_union

      updated_group = PeerGroup.new(
        dejima_tables: peer_group.dejima_tables,
        attributes: (peer_group.attributes - shared_attributes), # shared "moved up" to the union group
        peers: peer_group.peers
      )
      if updated_group.attributes.empty?
        peer_groups.delete(peer_group.dejima_tables)
      else
        updated_group.update_peers(new_group)
        peer_groups[peer_group.dejima_tables] = updated_group
      end
    end
    PeerGroups.update peer_groups
  end
end

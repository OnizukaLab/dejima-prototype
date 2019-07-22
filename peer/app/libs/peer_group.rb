# Helper class for storing Peer groups
#
# A peer group is identified by it's set of Dejima tables
# Further it holds a set of peer addresses and the attributes it is responsible for
#
# Note: To simplify the code, this assumes a no-transformation setup,
# where dependent attributes in different tables have the same attribute name
class PeerGroup
  attr_accessor :dejima_tables,
                :attributes,
                :peers

  def initialize(dejima_tables:, attributes: nil, peers: nil)
    # dejima_tables might be initialized with classes or strings from json responses.
    # old switcheroo solves that
    @dejima_tables = Set.new dejima_tables.map(&:to_s).map(&:constantize)
    @attributes = Set.new attributes
    @peers = Set.new peers
  end

  # update this groups peers based on another peer_group
  def update_peers(other_group)
    self.peers = peers.union other_group.peers
  end

  def as_json(_opts = {})
    {
      dejima_tables: dejima_tables.to_a.map(&:to_s),
      attributes: attributes.to_a,
      peers: peers.to_a
    }
  end
end

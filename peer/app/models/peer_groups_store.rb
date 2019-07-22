class PeerGroupsStore < ApplicationRecord
  before_create :singleton

  # custom serializer to handle PeerGroup object creation
  class PeerGroupsSerializer
    def self.load(peer_groups)
      serialized = {}
      peer_groups&.each_value do |value|
        peer_group = PeerGroup.new(value.symbolize_keys)
        serialized[peer_group.dejima_tables] = peer_group
      end
      serialized
    end

    def self.dump(peer_groups)
      peer_groups
    end
  end

  serialize :peer_groups, PeerGroupsSerializer

  def self.get
    first_or_create!
  end

  private

  def singleton
    raise Exception, "This is a singleton." if PeerGroupsStore.count > 0
  end
end

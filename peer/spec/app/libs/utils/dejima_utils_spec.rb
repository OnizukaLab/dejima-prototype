require 'rails_helper'

RSpec.describe DejimaUtils do
  describe "check_local_peer_groups" do
    it "Test" do
      DejimaUtils.check_local_peer_groups([GovernmentUser])
      require "pry"
      binding.pry
      DejimaUtils.detect_peer_groups
    end
  end
end

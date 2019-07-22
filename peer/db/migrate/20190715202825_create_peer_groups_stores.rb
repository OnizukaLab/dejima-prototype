class CreatePeerGroupsStores < ActiveRecord::Migration[5.2]
  def change
    create_table :peer_groups_stores do |t|
      t.jsonb 'peer_groups', default: {}
      t.boolean 'singleton', default: true, null: false

      t.timestamps
    end

    add_index(:peer_groups_stores, :singleton, :unique => true)
  end
end

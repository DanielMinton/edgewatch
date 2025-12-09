class CreateEdgeSites < ActiveRecord::Migration[8.1]
  def change
    create_table :edge_sites do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :api_endpoint, null: false
      t.string :api_token, null: false
      t.string :region
      t.string :environment, default: "production"
      t.integer :status, default: 0
      t.datetime :last_seen_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :edge_sites, :name
    add_index :edge_sites, :slug, unique: true
    add_index :edge_sites, :status
    add_index :edge_sites, :region
  end
end

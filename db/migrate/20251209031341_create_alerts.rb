class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.references :edge_site, null: false, foreign_key: true
      t.integer :severity, null: false, default: 0
      t.string :category, null: false
      t.string :title, null: false
      t.text :message
      t.string :metric_type
      t.decimal :threshold_value, precision: 10, scale: 4
      t.decimal :actual_value, precision: 10, scale: 4
      t.integer :status, default: 0
      t.datetime :triggered_at, null: false
      t.datetime :acknowledged_at
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :alerts, :severity
    add_index :alerts, :status
    add_index :alerts, :triggered_at
    add_index :alerts, %i[edge_site_id status], name: "idx_alerts_site_status"
  end
end

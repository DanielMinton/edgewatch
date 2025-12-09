class CreateMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :metrics do |t|
      t.references :edge_site, null: false, foreign_key: true
      t.string :metric_type, null: false
      t.decimal :value, precision: 10, scale: 4, null: false
      t.string :unit
      t.string :node_name
      t.string :pod_name
      t.string :namespace
      t.jsonb :labels, default: {}
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :metrics, :metric_type
    add_index :metrics, :recorded_at
    add_index :metrics, %i[edge_site_id metric_type recorded_at], name: "idx_metrics_site_type_time"
  end
end

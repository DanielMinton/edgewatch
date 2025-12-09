class AddNamespaceToEdgeSites < ActiveRecord::Migration[8.1]
  def change
    add_column :edge_sites, :namespace, :string
  end
end

class BroadcastMetricsJob < ApplicationJob
  queue_as :default

  def perform(edge_site_id)
    edge_site = EdgeSite.find(edge_site_id)

    ActionCable.server.broadcast(
      "dashboard_updates",
      {
        type: "metrics_updated",
        edge_site_id: edge_site.id,
        status: edge_site.status,
        last_seen_at: edge_site.last_seen_at&.iso8601
      }
    )
  end
end

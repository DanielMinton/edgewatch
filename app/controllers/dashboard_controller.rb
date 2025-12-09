class DashboardController < ApplicationController
  def index
    @edge_sites = EdgeSite.includes(:alerts)
                          .order(status: :desc, name: :asc)
    @total_alerts = Alert.unresolved.count
    @healthy_count = @edge_sites.count(&:healthy?)
    @degraded_count = @edge_sites.degraded.count + @edge_sites.critical.count
  end
end

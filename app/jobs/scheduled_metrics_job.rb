class ScheduledMetricsJob < ApplicationJob
  queue_as :default

  def perform
    EdgeSite.active.find_each do |edge_site|
      CollectMetricsJob.perform_later(edge_site.id)
    end
  end
end

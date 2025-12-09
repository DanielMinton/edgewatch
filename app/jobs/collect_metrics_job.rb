class CollectMetricsJob < ApplicationJob
  queue_as :metrics

  retry_on Kubernetes::ClientFactory::ConfigurationError, wait: 30.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(edge_site_id)
    edge_site = EdgeSite.find(edge_site_id)

    Rails.logger.info("[CollectMetricsJob] Collecting metrics for #{edge_site.name}")

    result = Kubernetes::MetricsCollector.new(edge_site).call

    if result.success
      Rails.logger.info("[CollectMetricsJob] Collected #{result.metrics.size} metrics for #{edge_site.name}")
    else
      Rails.logger.warn("[CollectMetricsJob] Partial failure for #{edge_site.name}: #{result.errors.join(', ')}")
    end

    schedule_next_collection(edge_site)
  end

  private

  def schedule_next_collection(edge_site)
    self.class.set(wait: 30.seconds).perform_later(edge_site.id)
  end
end

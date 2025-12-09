module Kubernetes
  class MetricsCollector
    Result = Data.define(:success, :metrics, :errors)

    def initialize(edge_site)
      @edge_site = edge_site
      @factory = ClientFactory.new(edge_site)
      @errors = []
    end

    def call
      metrics = []
      recorded_at = Time.current

      if namespace_scoped?
        # Sandbox/restricted access - only collect namespace-level metrics
        metrics.concat(collect_namespace_pod_metrics(recorded_at))
      else
        # Full cluster access
        metrics.concat(collect_node_metrics(recorded_at))
        metrics.concat(collect_pod_metrics(recorded_at))
      end

      persist_metrics(metrics) if metrics.any?
      update_site_status(metrics)
      broadcast_updates

      Result.new(
        success: errors.empty?,
        metrics: metrics,
        errors: errors
      )
    end

    def namespace_scoped?
      edge_site.namespace.present?
    end

    private

    attr_reader :edge_site, :factory, :errors

    def collect_node_metrics(recorded_at)
      nodes = factory.metrics_client.get_node_metrics

      nodes.flat_map do |node|
        build_node_metrics(node, recorded_at)
      end
    rescue Kubeclient::HttpError => e
      errors << "Node metrics unavailable: #{e.message}"
      []
    end

    def collect_pod_metrics(recorded_at)
      pods = factory.metrics_client.get_pod_metrics

      [
        Metric.new(
          edge_site: edge_site,
          metric_type: "pod_count",
          value: pods.size,
          unit: "count",
          recorded_at: recorded_at
        )
      ]
    rescue Kubeclient::HttpError => e
      errors << "Pod metrics unavailable: #{e.message}"
      []
    end

    def collect_namespace_pod_metrics(recorded_at)
      namespace = edge_site.namespace
      metrics = []

      # Get pods in namespace using core API
      begin
        pods = factory.core_client.get_pods(namespace: namespace)
        metrics << Metric.new(
          edge_site: edge_site,
          metric_type: "pod_count",
          value: pods.size,
          unit: "count",
          recorded_at: recorded_at
        )

        # Count running vs not running pods
        running_pods = pods.count { |p| p.status.phase == "Running" }
        metrics << Metric.new(
          edge_site: edge_site,
          metric_type: "running_pods",
          value: running_pods,
          unit: "count",
          recorded_at: recorded_at
        )
      rescue Kubeclient::HttpError => e
        errors << "Pod list unavailable: #{e.message}"
      end

      # Try to get pod metrics from metrics API (may not be available in sandbox)
      begin
        pod_metrics = factory.metrics_client.get_pod_metrics(namespace: namespace)
        pod_metrics.each do |pm|
          pm.containers.each do |container|
            cpu_nano = parse_cpu(container.usage.cpu)
            memory_bytes = parse_memory(container.usage.memory)

            metrics << Metric.new(
              edge_site: edge_site,
              metric_type: "cpu_millicores",
              value: (cpu_nano / 1_000_000.0).round(2),
              unit: "millicores",
              node_name: "#{pm.metadata.name}/#{container.name}",
              recorded_at: recorded_at
            )

            metrics << Metric.new(
              edge_site: edge_site,
              metric_type: "memory_mb",
              value: (memory_bytes / (1024.0 * 1024.0)).round(2),
              unit: "MB",
              node_name: "#{pm.metadata.name}/#{container.name}",
              recorded_at: recorded_at
            )
          end
        end
      rescue Kubeclient::HttpError => e
        errors << "Pod metrics API unavailable: #{e.message}"
      end

      metrics
    end

    def build_node_metrics(node, recorded_at)
      node_name = node.metadata.name
      cpu_nano = parse_cpu(node.usage.cpu)
      memory_bytes = parse_memory(node.usage.memory)

      [
        Metric.new(
          edge_site: edge_site,
          metric_type: "cpu_percent",
          value: calculate_cpu_percent(cpu_nano),
          unit: "percent",
          node_name: node_name,
          recorded_at: recorded_at
        ),
        Metric.new(
          edge_site: edge_site,
          metric_type: "memory_percent",
          value: calculate_memory_percent(memory_bytes),
          unit: "percent",
          node_name: node_name,
          recorded_at: recorded_at
        )
      ]
    end

    def parse_cpu(cpu_string)
      return 0 unless cpu_string

      case cpu_string
      when /(\d+)n$/
        Regexp.last_match(1).to_i
      when /(\d+)u$/
        Regexp.last_match(1).to_i * 1000
      when /(\d+)m$/
        Regexp.last_match(1).to_i * 1_000_000
      else
        cpu_string.to_i * 1_000_000_000
      end
    end

    def parse_memory(memory_string)
      return 0 unless memory_string

      case memory_string
      when /(\d+)Ki$/
        Regexp.last_match(1).to_i * 1024
      when /(\d+)Mi$/
        Regexp.last_match(1).to_i * 1024 * 1024
      when /(\d+)Gi$/
        Regexp.last_match(1).to_i * 1024 * 1024 * 1024
      else
        memory_string.to_i
      end
    end

    def calculate_cpu_percent(nano_cores, total_cores: 4)
      ((nano_cores.to_f / (total_cores * 1_000_000_000)) * 100).round(2)
    end

    def calculate_memory_percent(bytes, total_bytes: 8 * 1024 * 1024 * 1024)
      ((bytes.to_f / total_bytes) * 100).round(2)
    end

    def persist_metrics(metrics)
      Metric.transaction do
        metrics.each(&:save!)
      end
    rescue ActiveRecord::RecordInvalid => e
      errors << "Failed to persist metrics: #{e.message}"
    end

    def update_site_status(metrics)
      return edge_site.update!(status: :offline, last_seen_at: nil) if metrics.empty? && errors.any?

      # For namespace-scoped sites, check pod health
      if namespace_scoped?
        pod_count = metrics.find { |m| m.metric_type == "pod_count" }&.value || 0
        running_pods = metrics.find { |m| m.metric_type == "running_pods" }&.value || 0

        new_status = if pod_count == 0
                       :healthy # No pods is normal for empty namespace
                     elsif running_pods == pod_count
                       :healthy
                     elsif running_pods >= (pod_count * 0.7)
                       :degraded
                     else
                       :critical
                     end
      else
        # For cluster-level access, use CPU metrics
        cpu_metrics = metrics.select { |m| m.metric_type == "cpu_percent" }
        cpu_avg = cpu_metrics.any? ? cpu_metrics.sum(&:value) / cpu_metrics.size : 0

        new_status = case cpu_avg
                     when 0..70 then :healthy
                     when 70..85 then :degraded
                     else :critical
                     end
      end

      edge_site.update!(status: new_status, last_seen_at: Time.current)
    end

    def broadcast_updates
      # Skip broadcasting for now - real-time updates require ActionCable setup
      # EdgeSiteChannel.broadcast_to(edge_site, ...)
      Rails.logger.info("[MetricsCollector] Skipping broadcast for #{edge_site.name}")
    rescue StandardError => e
      # Don't fail the whole collection if broadcast fails
      Rails.logger.warn("[MetricsCollector] Broadcast failed: #{e.message}")
    end
  end
end

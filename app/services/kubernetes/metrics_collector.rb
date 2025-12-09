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

      metrics.concat(collect_node_metrics(recorded_at))
      metrics.concat(collect_pod_metrics(recorded_at))

      persist_metrics(metrics) if metrics.any?
      update_site_status(metrics)
      broadcast_updates

      Result.new(
        success: errors.empty?,
        metrics: metrics,
        errors: errors
      )
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

      cpu_metrics = metrics.select { |m| m.metric_type == "cpu_percent" }
      cpu_avg = cpu_metrics.any? ? cpu_metrics.sum(&:value) / cpu_metrics.size : 0

      new_status = case cpu_avg
                   when 0..70 then :healthy
                   when 70..85 then :degraded
                   else :critical
                   end

      edge_site.update!(status: new_status, last_seen_at: Time.current)
    end

    def broadcast_updates
      EdgeSiteChannel.broadcast_to(
        edge_site,
        turbo_stream.replace(
          "edge_site_#{edge_site.id}",
          partial: "dashboard/edge_site_card",
          locals: { edge_site: edge_site.reload }
        )
      )
    end

    def turbo_stream
      Turbo::Streams::TagBuilder.new(ApplicationController.helpers)
    end
  end
end

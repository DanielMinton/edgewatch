module Kubernetes
  class HealthChecker
    Result = Data.define(:healthy, :status, :details)

    def initialize(edge_site)
      @edge_site = edge_site
      @factory = ClientFactory.new(edge_site)
    end

    def call
      checks = {
        api_reachable: check_api_connectivity,
        nodes_ready: check_node_readiness,
        metrics_available: check_metrics_availability
      }

      healthy = checks.values.all? { |c| c[:ok] }
      status = determine_status(checks)

      Result.new(
        healthy: healthy,
        status: status,
        details: checks
      )
    rescue ClientFactory::ConfigurationError => e
      Result.new(
        healthy: false,
        status: :offline,
        details: { error: e.message }
      )
    end

    private

    attr_reader :edge_site, :factory

    def check_api_connectivity
      factory.core_client.api_valid?
      { ok: true, message: "API server responding" }
    rescue StandardError => e
      { ok: false, message: "API unreachable: #{e.message}" }
    end

    def check_node_readiness
      nodes = factory.core_client.get_nodes
      ready_count = nodes.count { |n| node_ready?(n) }
      total_count = nodes.size

      {
        ok: ready_count == total_count && total_count > 0,
        message: "#{ready_count}/#{total_count} nodes ready"
      }
    rescue StandardError => e
      { ok: false, message: "Failed to check nodes: #{e.message}" }
    end

    def check_metrics_availability
      factory.metrics_client.get_node_metrics
      { ok: true, message: "Metrics server available" }
    rescue StandardError => e
      { ok: false, message: "Metrics unavailable: #{e.message}" }
    end

    def node_ready?(node)
      conditions = node.status.conditions || []
      ready_condition = conditions.find { |c| c.type == "Ready" }
      ready_condition&.status == "True"
    end

    def determine_status(checks)
      return :offline unless checks[:api_reachable][:ok]
      return :critical unless checks[:nodes_ready][:ok]
      return :degraded unless checks[:metrics_available][:ok]
      :healthy
    end
  end
end

module Kubernetes
  class HealthChecker
    Result = Data.define(:healthy, :status, :details)

    def initialize(edge_site)
      @edge_site = edge_site
      @factory = ClientFactory.new(edge_site)
    end

    def call
      checks = if edge_site.namespace.present?
        # Namespace-scoped checks for sandbox/restricted access
        {
          api_reachable: check_api_connectivity,
          pods_healthy: check_pod_health,
          deployments_ready: check_deployments
        }
      else
        # Cluster-level checks for full access
        {
          api_reachable: check_api_connectivity,
          nodes_ready: check_node_readiness,
          metrics_available: check_metrics_availability
        }
      end

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

    def check_pod_health
      namespace = edge_site.namespace
      pods = factory.core_client.get_pods(namespace: namespace)
      running_count = pods.count { |p| p.status.phase == "Running" }
      total_count = pods.size

      {
        ok: total_count == 0 || running_count > 0,
        message: "#{running_count}/#{total_count} pods running",
        pod_count: total_count,
        running_count: running_count
      }
    rescue StandardError => e
      { ok: false, message: "Failed to check pods: #{e.message}" }
    end

    def check_deployments
      namespace = edge_site.namespace
      client = build_apps_client
      deployments = client.get_deployments(namespace: namespace)

      ready_count = deployments.count do |d|
        available = d.status.availableReplicas || 0
        desired = d.spec.replicas || 0
        available >= desired && desired > 0
      end
      total_count = deployments.size

      {
        ok: total_count == 0 || ready_count == total_count,
        message: "#{ready_count}/#{total_count} deployments ready",
        deployment_count: total_count,
        ready_count: ready_count
      }
    rescue StandardError => e
      { ok: false, message: "Failed to check deployments: #{e.message}" }
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

      if checks[:nodes_ready]
        return :critical unless checks[:nodes_ready][:ok]
        return :degraded unless checks[:metrics_available][:ok]
      else
        return :critical unless checks[:pods_healthy][:ok]
        return :degraded unless checks[:deployments_ready][:ok]
      end

      :healthy
    end

    def build_apps_client
      base = edge_site.api_endpoint.chomp("/")
      Kubeclient::Client.new(
        "#{base}/apis/apps",
        "v1",
        auth_options: { bearer_token: edge_site.api_token },
        ssl_options: { verify_ssl: Rails.env.production? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE },
        timeouts: { open: 5, read: 30 }
      )
    end
  end
end

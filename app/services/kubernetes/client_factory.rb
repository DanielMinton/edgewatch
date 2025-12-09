module Kubernetes
  class ClientFactory
    class ConfigurationError < StandardError; end

    def initialize(edge_site)
      @edge_site = edge_site
    end

    def core_client
      build_client("v1")
    end

    def metrics_client
      build_client("metrics.k8s.io/v1beta1")
    end

    private

    attr_reader :edge_site

    def build_client(api_version)
      Kubeclient::Client.new(
        api_endpoint_for(api_version),
        api_version,
        auth_options: auth_options,
        ssl_options: ssl_options,
        timeouts: { open: 5, read: 30 }
      )
    rescue StandardError => e
      Rails.logger.error("[Kubernetes::ClientFactory] Failed to build client: #{e.message}")
      raise ConfigurationError, "Unable to connect to cluster: #{e.message}"
    end

    def api_endpoint_for(api_version)
      base = edge_site.api_endpoint.chomp("/")

      case api_version
      when "v1"
        "#{base}/api"
      else
        "#{base}/apis/#{api_version.split('/').first}"
      end
    end

    def auth_options
      { bearer_token: edge_site.api_token }
    end

    def ssl_options
      {
        verify_ssl: production? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      }
    end

    def production?
      Rails.env.production?
    end
  end
end

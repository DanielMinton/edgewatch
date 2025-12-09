class EdgeSitesController < ApplicationController
  before_action :set_edge_site, only: %i[show edit update destroy metrics collect_metrics]

  def index
    @edge_sites = EdgeSite.order(:name)
  end

  def show
    @metrics = @edge_site.metrics.recent.for_chart
    @alerts = @edge_site.alerts.unresolved.recent
  end

  def new
    @edge_site = EdgeSite.new
  end

  def edit
  end

  def create
    @edge_site = EdgeSite.new(edge_site_params)

    if @edge_site.save
      begin
        CollectMetricsJob.perform_later(@edge_site.id)
      rescue StandardError => e
        Rails.logger.warn("[EdgeSitesController] Failed to queue metrics job: #{e.message}")
      end
      redirect_to @edge_site, notice: "Edge site registered successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @edge_site.update(edge_site_params)
      redirect_to @edge_site, notice: "Edge site updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @edge_site.destroy
    redirect_to edge_sites_path, notice: "Edge site removed."
  end

  def metrics
    @metrics = @edge_site.metrics
                         .by_type(params[:type] || "cpu_percent")
                         .for_chart

    render json: {
      labels: @metrics.map { |m| m.recorded_at.strftime("%H:%M") },
      values: @metrics.map(&:value)
    }
  end

  def collect_metrics
    begin
      result = Kubernetes::MetricsCollector.new(@edge_site).call
      if result.success
        redirect_to @edge_site, notice: "Collected #{result.metrics.size} metrics successfully."
      else
        redirect_to @edge_site, alert: "Partial success: #{result.errors.join(', ')}"
      end
    rescue StandardError => e
      Rails.logger.error("[EdgeSitesController] Metrics collection failed: #{e.message}")
      redirect_to @edge_site, alert: "Failed to collect metrics: #{e.message}"
    end
  end

  private

  def set_edge_site
    @edge_site = EdgeSite.find_by!(slug: params[:id])
  end

  def edge_site_params
    params.require(:edge_site).permit(:name, :api_endpoint, :api_token, :namespace, :region, :environment)
  end
end

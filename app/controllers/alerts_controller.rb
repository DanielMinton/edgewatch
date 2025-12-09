class AlertsController < ApplicationController
  before_action :set_alert, only: %i[show update acknowledge resolve]

  def index
    @alerts = Alert.includes(:edge_site)
                   .order(triggered_at: :desc)
                   .limit(100)
  end

  def show
  end

  def update
    if @alert.update(alert_params)
      redirect_to @alert, notice: "Alert updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def acknowledge
    @alert.acknowledge!
    redirect_back fallback_location: alerts_path, notice: "Alert acknowledged."
  end

  def resolve
    @alert.resolve!
    redirect_back fallback_location: alerts_path, notice: "Alert resolved."
  end

  private

  def set_alert
    @alert = Alert.find(params[:id])
  end

  def alert_params
    params.require(:alert).permit(:status)
  end
end

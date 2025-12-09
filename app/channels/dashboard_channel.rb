class DashboardChannel < ApplicationCable::Channel
  def subscribed
    stream_from "dashboard_updates"
  end
end

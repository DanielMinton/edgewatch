class EdgeSiteChannel < ApplicationCable::Channel
  def subscribed
    edge_site = EdgeSite.find_by(id: params[:edge_site_id])

    if edge_site
      stream_for edge_site
      Rails.logger.info("[EdgeSiteChannel] Client subscribed to site: #{edge_site.slug}")
    else
      reject
    end
  end

  def unsubscribed
    Rails.logger.info("[EdgeSiteChannel] Client unsubscribed")
  end
end

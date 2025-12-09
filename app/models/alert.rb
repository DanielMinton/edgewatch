class Alert < ApplicationRecord
  belongs_to :edge_site

  enum :severity, { info: 0, warning: 1, error: 2, critical: 3 }
  enum :status, { active: 0, acknowledged: 1, resolved: 2 }, prefix: :is

  validates :title, presence: true
  validates :category, presence: true
  validates :triggered_at, presence: true

  scope :unresolved, -> { where.not(status: :resolved) }
  scope :recent, -> { order(triggered_at: :desc).limit(50) }

  def acknowledge!(user = nil)
    update!(status: :acknowledged, acknowledged_at: Time.current)
  end

  def resolve!
    update!(status: :resolved, resolved_at: Time.current)
  end

  def duration
    return nil unless triggered_at

    end_time = resolved_at || Time.current
    end_time - triggered_at
  end
end

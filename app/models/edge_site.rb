class EdgeSite < ApplicationRecord
  encrypts :api_endpoint, :api_token

  enum :status, { unknown: 0, healthy: 1, degraded: 2, critical: 3, offline: 4 }

  has_many :metrics, dependent: :destroy
  has_many :alerts, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :api_endpoint, presence: true

  before_validation :generate_slug, on: :create

  scope :active, -> { where.not(status: :offline) }
  scope :by_region, ->(region) { where(region: region) }

  def healthy?
    status == "healthy" && last_seen_at && last_seen_at > 5.minutes.ago
  end

  def latest_metrics
    metrics.order(recorded_at: :desc).limit(60)
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug ||= name&.parameterize
  end
end

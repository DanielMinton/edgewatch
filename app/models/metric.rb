class Metric < ApplicationRecord
  belongs_to :edge_site, touch: true

  TYPES = %w[cpu_percent memory_percent disk_percent network_rx network_tx pod_count node_count].freeze

  validates :metric_type, presence: true, inclusion: { in: TYPES }
  validates :value, presence: true, numericality: true
  validates :recorded_at, presence: true

  scope :recent, -> { where(recorded_at: 1.hour.ago..) }
  scope :by_type, ->(type) { where(metric_type: type) }
  scope :for_chart, -> { order(recorded_at: :asc).limit(60) }

  def self.latest_by_type(type)
    by_type(type).order(recorded_at: :desc).first
  end

  def self.average_over(duration, type:)
    by_type(type)
      .where(recorded_at: duration.ago..)
      .average(:value)
      &.round(2)
  end
end

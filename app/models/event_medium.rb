class EventMedium < ApplicationRecord
  belongs_to :event

  validates :url, presence: true
  validates :media_type, inclusion: { in: %w[image video] }

  scope :images, -> { where(media_type: "image") }
  scope :videos, -> { where(media_type: "video") }
  scope :featured, -> { where(is_featured: true) }
  scope :ordered, -> { order(display_order: :asc) }

  def image?
    media_type == "image"
  end

  def video?
    media_type == "video"
  end

  def self.table_name
    "event_media"
  end
end

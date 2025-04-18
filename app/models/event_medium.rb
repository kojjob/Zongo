class EventMedium < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true

  # Add Active Storage attachment
  has_one_attached :image

  # Log when a new record is created
  after_create :log_creation

  def log_creation
    Rails.logger.debug "Created EventMedium #{id} for event #{event_id}"
    Rails.logger.debug "Image attached: #{image.attached?}"
  end

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

  # Get the URL for the image
  def image_url
    if image.attached?
      begin
        # Use the variant processor to generate a URL
        Rails.application.routes.url_helpers.url_for(image)
      rescue => e
        # Log the error and fall back to the URL field or a placeholder
        Rails.logger.error("Error generating image URL: #{e.message}")
        url.presence || "/assets/event-placeholder.png"
      end
    else
      # Fallback to the URL field or a placeholder
      url.presence || "/assets/event-placeholder.png"
    end
  end

  def self.table_name
    "event_media"
  end
end

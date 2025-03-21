# Configure Active Storage routes
Rails.application.config.active_storage.routes_prefix = '/storage'

# Ensure proper handling of variants
Rails.application.config.active_storage.variant_processor = :mini_magick

# Set service URLs to be non-expiring by default
Rails.application.config.active_storage.service_urls_expire_in = 1.hour

# Set replace_on_assign_to_many to false for smoother handling of attachments
Rails.application.config.active_storage.replace_on_assign_to_many = false

# Log Active Storage calls
Rails.application.config.active_storage.track_variants = true

# Configure allowed content types (optional, you can uncomment and adjust as needed)
# Rails.application.config.active_storage.web_image_content_types = ["image/png", "image/jpeg", "image/gif"]

# Configure Direct Route support for Active Storage
Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    # Add direct route support for Active Storage blobs
    def public_url(**options)
      Rails.application.routes.url_helpers.rails_blob_url(self, **options)
    end
  end
end
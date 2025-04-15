class AddFieldsToEventMedia < ActiveRecord::Migration[7.0]
  def change
    # Add URL field to event_media
    unless column_exists?(:event_media, :url)
      add_column :event_media, :url, :string
    end

    # Add caption field if it doesn't exist
    unless column_exists?(:event_media, :caption)
      add_column :event_media, :caption, :text
    end
  end
end

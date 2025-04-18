class AddAnalyticsFieldsToEventViews < ActiveRecord::Migration[8.0]
  def change
    # Add new fields to event_views table if it exists
    if table_exists?(:event_views)
      # Check if the column exists with a different name (referrer vs referer)
      unless column_exists?(:event_views, :referer) || column_exists?(:event_views, :referrer)
        add_column :event_views, :referer, :string
      end

      unless column_exists?(:event_views, :viewed_at)
        add_column :event_views, :viewed_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
      end
    end

    # Make sure views_count exists on events table
    unless column_exists?(:events, :views_count)
      # Check if event_views_count exists instead
      if column_exists?(:events, :event_views_count)
        # Rename the column to match our new code
        rename_column :events, :event_views_count, :views_count
      else
        add_column :events, :views_count, :integer, default: 0
      end
    end
  end
end

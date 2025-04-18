class EnsureEventViewsTableExists < ActiveRecord::Migration[8.0]
  def change
    # Only create the table if it doesn't exist
    unless table_exists?(:event_views)
      create_table :event_views do |t|
        t.references :event, null: false, foreign_key: true, index: true
        t.references :user, null: true, foreign_key: true, index: true
        t.string :ip_address, null: false
        t.string :user_agent
        t.string :referer
        t.string :referrer
        t.datetime :viewed_at, default: -> { 'CURRENT_TIMESTAMP' }

        t.timestamps
      end

      # Add index for efficient queries on IP + event within a time period
      add_index :event_views, [ :event_id, :ip_address, :created_at ]
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

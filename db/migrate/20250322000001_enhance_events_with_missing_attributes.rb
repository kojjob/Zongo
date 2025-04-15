class EnhanceEventsWithMissingAttributes < ActiveRecord::Migration[7.0]
  def change
    # Add missing fields to events, only if they don't exist
    unless column_exists?(:events, :price)
      add_column :events, :price, :decimal, precision: 10, scale: 2, default: 0
    end

    unless column_exists?(:events, :event_type)
      add_column :events, :event_type, :string
    end

    # Skip these columns as they already exist in the original migration
    # capacity
    # is_featured
    # organizer_id
    # venue_id
    # The category_id would conflict with event_category_id
  end
end

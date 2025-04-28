class UpdateRideBookingsTable < ActiveRecord::Migration[8.0]
  def change
    # Add references to recent locations if they don't exist
    unless column_exists?(:ride_bookings, :origin_location_id)
      add_reference :ride_bookings, :origin_location, foreign_key: { to_table: :recent_locations }, index: true
    end

    unless column_exists?(:ride_bookings, :destination_location_id)
      add_reference :ride_bookings, :destination_location, foreign_key: { to_table: :recent_locations }, index: true
    end

    # Handle status column conversion if it exists and is a string
    if column_exists?(:ride_bookings, :status) && !column_exists?(:ride_bookings, :status_string)
      # Check column type
      if column_for_attribute(:ride_bookings, :status).type == :string
        # Change string status to integer status with enum
        rename_column :ride_bookings, :status, :status_string
        add_column :ride_bookings, :status, :integer, default: 0, null: false

        # Add data migration to convert status_string to status integer
        reversible do |dir|
          dir.up do
            execute <<-SQL
              UPDATE ride_bookings
              SET status = CASE
                WHEN status_string = 'pending' THEN 0
                WHEN status_string = 'confirmed' THEN 1
                WHEN status_string = 'in_progress' THEN 2
                WHEN status_string = 'completed' THEN 3
                WHEN status_string = 'cancelled' THEN 4
                ELSE 0
              END
            SQL
          end
        end
      end
    elsif !column_exists?(:ride_bookings, :status)
      # Add status column if it doesn't exist
      add_column :ride_bookings, :status, :integer, default: 0, null: false
    end

    # Handle ride_type column conversion if it exists and is a string
    if column_exists?(:ride_bookings, :ride_type) && !column_exists?(:ride_bookings, :ride_type_string)
      # Check column type
      if column_for_attribute(:ride_bookings, :ride_type).type == :string
        # Change string ride_type to integer ride_type with enum
        rename_column :ride_bookings, :ride_type, :ride_type_string
        add_column :ride_bookings, :ride_type, :integer, default: 1, null: false

        # Add data migration to convert ride_type_string to ride_type integer
        reversible do |dir|
          dir.up do
            execute <<-SQL
              UPDATE ride_bookings
              SET ride_type = CASE
                WHEN ride_type_string = 'economy' THEN 0
                WHEN ride_type_string = 'standard' THEN 1
                WHEN ride_type_string = 'premium' THEN 2
                ELSE 1
              END
            SQL
          end
        end
      end
    elsif !column_exists?(:ride_bookings, :ride_type)
      # Add ride_type column if it doesn't exist
      add_column :ride_bookings, :ride_type, :integer, default: 1, null: false
    end

    # Add new columns if they don't exist
    unless column_exists?(:ride_bookings, :distance_km)
      add_column :ride_bookings, :distance_km, :decimal, precision: 8, scale: 2
    end

    unless column_exists?(:ride_bookings, :duration_minutes)
      add_column :ride_bookings, :duration_minutes, :integer
    end

    unless column_exists?(:ride_bookings, :driver_id)
      add_column :ride_bookings, :driver_id, :string
    end

    unless column_exists?(:ride_bookings, :vehicle_id)
      add_column :ride_bookings, :vehicle_id, :string
    end

    unless column_exists?(:ride_bookings, :notes)
      add_column :ride_bookings, :notes, :text
    end

    unless column_exists?(:ride_bookings, :metadata)
      add_column :ride_bookings, :metadata, :json
    end

    # Add indexes if they don't exist
    unless index_exists?(:ride_bookings, :status)
      add_index :ride_bookings, :status
    end

    unless index_exists?(:ride_bookings, :ride_type)
      add_index :ride_bookings, :ride_type
    end

    unless index_exists?(:ride_bookings, :pickup_time)
      add_index :ride_bookings, :pickup_time
    end
  end

  private

  def column_for_attribute(table, column_name)
    connection.columns(table).find { |c| c.name == column_name.to_s }
  end
end

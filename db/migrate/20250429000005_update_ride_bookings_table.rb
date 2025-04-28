class UpdateRideBookingsTable < ActiveRecord::Migration[8.0]
  def change
    # Add references to recent locations
    add_reference :ride_bookings, :origin_location, foreign_key: { to_table: :recent_locations }, index: true
    add_reference :ride_bookings, :destination_location, foreign_key: { to_table: :recent_locations }, index: true
    
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
    
    # Add new columns
    add_column :ride_bookings, :distance_km, :decimal, precision: 8, scale: 2
    add_column :ride_bookings, :duration_minutes, :integer
    add_column :ride_bookings, :driver_id, :string
    add_column :ride_bookings, :vehicle_id, :string
    add_column :ride_bookings, :notes, :text
    add_column :ride_bookings, :metadata, :json
    
    # Add indexes
    add_index :ride_bookings, :status
    add_index :ride_bookings, :ride_type
    add_index :ride_bookings, :pickup_time
  end
end

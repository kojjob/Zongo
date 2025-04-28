class CreateRideBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :ride_bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :origin_location, foreign_key: { to_table: :recent_locations }
      t.references :destination_location, foreign_key: { to_table: :recent_locations }
      t.string :origin_address, null: false
      t.string :destination_address, null: false
      t.decimal :origin_latitude, precision: 10, scale: 6
      t.decimal :origin_longitude, precision: 10, scale: 6
      t.decimal :destination_latitude, precision: 10, scale: 6
      t.decimal :destination_longitude, precision: 10, scale: 6
      t.datetime :pickup_time, null: false
      t.datetime :dropoff_time
      t.decimal :distance_km, precision: 8, scale: 2
      t.integer :duration_minutes
      t.decimal :price, precision: 10, scale: 2
      t.string :currency, default: "GHS"
      t.integer :status, default: 0, null: false
      t.integer :ride_type, default: 1, null: false
      t.string :driver_id
      t.string :vehicle_id
      t.text :notes
      t.json :metadata

      t.timestamps
    end
    
    add_index :ride_bookings, :status
    add_index :ride_bookings, :ride_type
    add_index :ride_bookings, :pickup_time
  end
end

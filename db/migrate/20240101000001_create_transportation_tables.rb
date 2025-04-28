class CreateTransportationTables < ActiveRecord::Migration[7.1]
  def change
    create_table :recent_locations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.string :location_type
      t.timestamps
    end

    create_table :routes do |t|
      t.string :origin, null: false
      t.string :destination, null: false
      t.decimal :distance, precision: 10, scale: 2, null: false
      t.string :transport_type
      t.integer :bookings_count, default: 0
      t.timestamps
    end

    create_table :ride_bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :origin, null: false
      t.string :destination, null: false
      t.decimal :origin_latitude, precision: 10, scale: 6
      t.decimal :origin_longitude, precision: 10, scale: 6
      t.decimal :destination_latitude, precision: 10, scale: 6
      t.decimal :destination_longitude, precision: 10, scale: 6
      t.datetime :pickup_time, null: false
      t.datetime :dropoff_time
      t.string :status, default: "pending"
      t.string :ride_type
      t.string :driver_name
      t.string :driver_phone
      t.string :vehicle_model
      t.string :vehicle_color
      t.string :license_plate
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :payment_method
      t.string :payment_status, default: "pending"
      t.timestamps
    end

    create_table :ticket_bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :route, null: false, foreign_key: true
      t.string :company_name
      t.string :transport_type, null: false
      t.datetime :departure_time, null: false
      t.datetime :arrival_time, null: false
      t.integer :passengers, default: 1
      t.string :status, default: "confirmed"
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :payment_method
      t.string :payment_status, default: "paid"
      t.string :ticket_number
      t.text :notes
      t.timestamps
    end
  end
end

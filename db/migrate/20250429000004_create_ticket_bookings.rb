class CreateTicketBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :transport_company, foreign_key: true
      t.references :route, foreign_key: true
      t.string :booking_reference
      t.string :origin, null: false
      t.string :destination, null: false
      t.datetime :departure_time, null: false
      t.datetime :arrival_time
      t.integer :passengers, default: 1, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :currency, default: "GHS"
      t.integer :status, default: 0, null: false
      t.integer :transport_type, default: 0, null: false
      t.string :seat_numbers
      t.text :notes
      t.json :amenities
      t.json :metadata

      t.timestamps
    end
    
    add_index :ticket_bookings, :booking_reference, unique: true
    add_index :ticket_bookings, :status
    add_index :ticket_bookings, :transport_type
    add_index :ticket_bookings, :departure_time
  end
end

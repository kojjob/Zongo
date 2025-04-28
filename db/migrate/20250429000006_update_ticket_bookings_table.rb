class UpdateTicketBookingsTable < ActiveRecord::Migration[8.0]
  def change
    # Add reference to transport_company
    add_reference :ticket_bookings, :transport_company, foreign_key: true, index: true
    
    # Add booking reference
    add_column :ticket_bookings, :booking_reference, :string
    add_index :ticket_bookings, :booking_reference, unique: true
    
    # Change string status to integer status with enum
    rename_column :ticket_bookings, :status, :status_string
    add_column :ticket_bookings, :status, :integer, default: 0, null: false
    
    # Add data migration to convert status_string to status integer
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE ticket_bookings 
          SET status = CASE 
            WHEN status_string = 'pending' THEN 0
            WHEN status_string = 'confirmed' THEN 1
            WHEN status_string = 'completed' THEN 2
            WHEN status_string = 'cancelled' THEN 3
            WHEN status_string = 'refunded' THEN 4
            ELSE 0
          END
        SQL
      end
    end
    
    # Change string transport_type to integer transport_type with enum
    rename_column :ticket_bookings, :transport_type, :transport_type_string
    add_column :ticket_bookings, :transport_type, :integer, default: 0, null: false
    
    # Add data migration to convert transport_type_string to transport_type integer
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE ticket_bookings 
          SET transport_type = CASE 
            WHEN transport_type_string = 'bus' THEN 0
            WHEN transport_type_string = 'train' THEN 1
            WHEN transport_type_string = 'ferry' THEN 2
            WHEN transport_type_string = 'plane' THEN 3
            ELSE 0
          END
        SQL
      end
    end
    
    # Add new columns
    add_column :ticket_bookings, :seat_numbers, :string
    add_column :ticket_bookings, :amenities, :json
    add_column :ticket_bookings, :metadata, :json
    
    # Add indexes
    add_index :ticket_bookings, :status
    add_index :ticket_bookings, :transport_type
    add_index :ticket_bookings, :departure_time
  end
end

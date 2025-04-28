class UpdateTicketBookingsTable < ActiveRecord::Migration[8.0]
  def change
    # Add reference to transport_company if it doesn't exist
    unless column_exists?(:ticket_bookings, :transport_company_id)
      add_reference :ticket_bookings, :transport_company, foreign_key: true, index: true
    end

    # Add booking reference if it doesn't exist
    unless column_exists?(:ticket_bookings, :booking_reference)
      add_column :ticket_bookings, :booking_reference, :string
      add_index :ticket_bookings, :booking_reference, unique: true
    end

    # Handle status column conversion if it exists and is a string
    if column_exists?(:ticket_bookings, :status) && !column_exists?(:ticket_bookings, :status_string)
      # Check column type
      if column_for_attribute(:ticket_bookings, :status).type == :string
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
      end
    elsif !column_exists?(:ticket_bookings, :status)
      # Add status column if it doesn't exist
      add_column :ticket_bookings, :status, :integer, default: 0, null: false
    end

    # Handle transport_type column conversion if it exists and is a string
    if column_exists?(:ticket_bookings, :transport_type) && !column_exists?(:ticket_bookings, :transport_type_string)
      # Check column type
      if column_for_attribute(:ticket_bookings, :transport_type).type == :string
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
      end
    elsif !column_exists?(:ticket_bookings, :transport_type)
      # Add transport_type column if it doesn't exist
      add_column :ticket_bookings, :transport_type, :integer, default: 0, null: false
    end

    # Add new columns if they don't exist
    unless column_exists?(:ticket_bookings, :seat_numbers)
      add_column :ticket_bookings, :seat_numbers, :string
    end

    unless column_exists?(:ticket_bookings, :amenities)
      add_column :ticket_bookings, :amenities, :json
    end

    unless column_exists?(:ticket_bookings, :metadata)
      add_column :ticket_bookings, :metadata, :json
    end

    # Add indexes if they don't exist
    unless index_exists?(:ticket_bookings, :status)
      add_index :ticket_bookings, :status
    end

    unless index_exists?(:ticket_bookings, :transport_type)
      add_index :ticket_bookings, :transport_type
    end

    unless index_exists?(:ticket_bookings, :departure_time)
      add_index :ticket_bookings, :departure_time
    end
  end

  private

  def column_for_attribute(table, column_name)
    connection.columns(table).find { |c| c.name == column_name.to_s }
  end
end

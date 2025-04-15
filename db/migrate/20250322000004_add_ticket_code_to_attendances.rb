class AddTicketCodeToAttendances < ActiveRecord::Migration[7.0]
  def change
    # Add ticket_code field if it doesn't exist
    unless column_exists?(:attendances, :ticket_code)
      add_column :attendances, :ticket_code, :string
    end

    # Change status to string if it's an integer
    # (only if needed - commented out for safety)
    # change_column :attendances, :status, :string, default: 'confirmed'

    # Add notes field if it doesn't exist
    unless column_exists?(:attendances, :notes)
      add_column :attendances, :notes, :text
    end
  end
end

class CreateEventTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :event_tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :ticket_type, null: false, foreign_key: true
      t.references :attendance, null: false, foreign_key: true
      t.string :ticket_code, null: false
      t.integer :status, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.datetime :used_at
      t.datetime :refunded_at
      t.string :payment_reference
      t.string :transaction_id

      t.timestamps
    end

    add_index :event_tickets, :ticket_code, unique: true
    add_index :event_tickets, :status
  end
end

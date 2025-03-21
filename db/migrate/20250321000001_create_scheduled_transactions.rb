class CreateScheduledTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_transactions do |t|
      t.references :source_wallet, null: false, foreign_key: { to_table: :wallets }
      t.references :destination_wallet, foreign_key: { to_table: :wallets }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :transaction_type, null: false, default: 0
      t.integer :frequency, null: false, default: 2 # Default to monthly
      t.datetime :next_occurrence, null: false
      t.datetime :last_occurrence
      t.integer :status, null: false, default: 0 # Default to active
      t.integer :occurrences_count, default: 0
      t.integer :occurrences_limit
      t.string :description
      t.string :payment_method
      t.string :payment_provider
      t.string :payment_destination
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :scheduled_transactions, :next_occurrence
    add_index :scheduled_transactions, :status
  end
end
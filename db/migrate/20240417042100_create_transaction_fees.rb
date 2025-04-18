class CreateTransactionFees < ActiveRecord::Migration[7.0]
  def change
    # Only create the table if it doesn't exist
    unless table_exists?(:transaction_fees)
      create_table :transaction_fees do |t|
        t.string :name, null: false
        t.integer :transaction_type, null: false, default: 4 # Default to 'all'
        t.integer :fee_type, null: false, default: 0 # Default to 'fixed'
        t.decimal :fixed_amount, precision: 10, scale: 2
        t.decimal :percentage, precision: 5, scale: 2
        t.decimal :min_fee, precision: 10, scale: 2
        t.decimal :max_fee, precision: 10, scale: 2
        t.boolean :active, default: true
        t.text :description

        t.timestamps
      end

      # Add indexes only if we created the table
      add_index :transaction_fees, :transaction_type
      add_index :transaction_fees, :active
    end
  end
end

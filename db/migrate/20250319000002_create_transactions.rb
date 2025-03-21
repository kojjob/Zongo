class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:transactions)
    
    create_table :transactions do |t|
      # Transaction unique identifier
      t.string :transaction_id, null: false, index: { unique: true }
      
      # Transaction type (deposit, withdrawal, transfer, payment)
      t.integer :transaction_type, null: false
      
      # Status (pending, completed, failed, reversed)
      t.integer :status, default: 0, null: false
      
      # Amount with sufficient precision for financial transactions
      t.decimal :amount, precision: 10, scale: 2, null: false
      
      # Currency (ISO code)
      t.string :currency, default: 'GHS', null: false
      
      # Fee amount (if any)
      t.decimal :fee, precision: 8, scale: 2, default: 0, null: false
      
      # Source and destination relationships
      # For transfers, both would be populated
      # For deposits/withdrawals, only one would be populated
      t.references :source_wallet, foreign_key: { to_table: :wallets }, null: true
      t.references :destination_wallet, foreign_key: { to_table: :wallets }, null: true
      
      # External references (for payment providers, bank transfers)
      t.string :external_reference
      t.string :provider_reference
      
      # Payment method used (mobile_money, bank, card, cash)
      t.integer :payment_method
      
      # Payment provider (MTN, Vodafone, AirtelTigo, etc.)
      t.string :provider
      
      # Description/memo/notes
      t.string :description
      
      # Metadata for additional transaction details (JSON)
      t.jsonb :metadata, default: {}
      
      # IP address for audit and security
      t.string :ip_address
      
      # User agent for audit and security
      t.string :user_agent
      
      # Timestamps for transaction lifecycle
      t.datetime :initiated_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.datetime :reversed_at
      
      t.timestamps
    end
    
    # Add indexes for faster lookups and reporting
    add_index :transactions, :transaction_type
    add_index :transactions, :status
    add_index :transactions, :initiated_at
    add_index :transactions, :payment_method
    add_index :transactions, :provider
  end
end

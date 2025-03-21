class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:wallets)
    
    create_table :wallets do |t|
      # Reference to user
      t.references :user, null: false, foreign_key: true
      
      # Unique wallet identifier (for external references)
      t.string :wallet_id, null: false, index: { unique: true }
      
      # Wallet status
      t.integer :status, default: 0, null: false
      
      # Balance fields - Using decimal with precision for money
      # (8,2) allows tracking up to 999,999.99 which should be sufficient
      # Consider adjusting precision if larger amounts are expected
      t.decimal :balance, precision: 10, scale: 2, default: 0, null: false
      
      # Default currency (using ISO code)
      t.string :currency, default: 'GHS', null: false
      
      # Daily transaction limit (for security)
      t.decimal :daily_limit, precision: 10, scale: 2, default: 1000, null: false
      
      # Security and audit fields
      t.datetime :last_transaction_at
      t.string :last_ip_address
      
      t.timestamps
    end
    
    # Add index for faster lookups by wallet_id
  end
end

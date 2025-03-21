class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:payment_methods)
    
    create_table :payment_methods do |t|
      # User association
      t.references :user, null: false, foreign_key: true
      
      # Payment method type (mobile_money, bank_account, card)
      t.integer :method_type, null: false
      
      # Provider (MTN, Vodafone, AirtelTigo, specific bank names)
      t.string :provider, null: false
      
      # Account details (encrypted)
      t.string :account_number_digest
      
      # Account holder name (for bank accounts)
      t.string :account_name
      
      # Mobile money phone number (if applicable)
      t.string :phone_number
      
      # For cards: masked card number, expiry, card type
      t.string :masked_number
      t.string :expiry_date
      t.string :card_type
      
      # Default payment method flag
      t.boolean :default, default: false
      
      # Status (active, disabled)
      t.integer :status, default: 0, null: false
      
      # Verification status
      t.integer :verification_status, default: 0, null: false
      
      # Last used timestamp
      t.datetime :last_used_at
      
      t.timestamps
    end
    
    # Add indexes for faster lookups
    add_index :payment_methods, [:user_id, :method_type]
    add_index :payment_methods, [:user_id, :default]
    add_index :payment_methods, :status
  end
end

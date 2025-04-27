class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.integer :status, default: 0, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.decimal :shipping_cost, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.string :shipping_address
      t.string :billing_address
      t.string :payment_method
      t.references :transaction, foreign_key: true
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :cancelled_at
      t.string :tracking_number
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :orders, :order_number, unique: true
    add_index :orders, :status
  end
end

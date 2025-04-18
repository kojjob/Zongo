class CreateBillPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :bill_payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :transaction, foreign_key: true
      t.integer :bill_type, default: 0, null: false
      t.string :provider, null: false
      t.string :account_number, null: false
      t.string :package
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :fee, precision: 10, scale: 2, default: 0.0
      t.integer :status, default: 0, null: false
      t.string :reference_number
      t.text :description

      t.timestamps
    end

    add_index :bill_payments, :reference_number, unique: true
  end
end

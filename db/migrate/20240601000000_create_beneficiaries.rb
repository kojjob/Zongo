class CreateBeneficiaries < ActiveRecord::Migration[8.0]
  def change
    create_table :beneficiaries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_number, null: false
      t.string :bank_name
      t.string :phone_number
      t.integer :transfer_type, default: 0, null: false
      t.integer :usage_count, default: 0, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :beneficiaries, [ :user_id, :account_number ], unique: true
  end
end

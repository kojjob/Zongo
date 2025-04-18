class CreateLoanRepayments < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_repayments do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :transaction, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :principal_amount, precision: 10, scale: 2, null: false
      t.decimal :interest_amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0
      t.date :due_date
      t.datetime :paid_at

      t.timestamps
    end

    add_index :loan_repayments, :status
    add_index :loan_repayments, :due_date
  end
end

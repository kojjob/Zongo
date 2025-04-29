class CreateLoanRefinancings < ActiveRecord::Migration[7.1]
  def change
    create_table :loan_refinancings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :original_loan, null: false, foreign_key: { to_table: :loans }
      t.references :new_loan, foreign_key: { to_table: :loans }
      t.decimal :requested_amount, precision: 10, scale: 2, null: false
      t.decimal :original_rate, precision: 5, scale: 2, null: false
      t.decimal :requested_rate, precision: 5, scale: 2, null: false
      t.decimal :estimated_savings, precision: 10, scale: 2
      t.integer :term_days, null: false
      t.integer :status, default: 0, null: false
      t.text :reason
      t.text :rejection_reason
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :cancelled_at

      t.timestamps
    end
    
    add_index :loan_refinancings, :status
  end
end

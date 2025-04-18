class CreateLoansIfNotExists < ActiveRecord::Migration[8.0]
  def change
    # Check if loans table exists
    unless table_exists?(:loans)
      create_table :loans do |t|
        t.references :user, null: false, foreign_key: true
        t.references :wallet, null: false, foreign_key: true
        t.string :reference_number, null: false
        t.integer :loan_type, default: 0
        t.decimal :amount, precision: 10, scale: 2, null: false
        t.decimal :interest_rate, precision: 5, scale: 2, null: false
        t.integer :term_days, null: false
        t.date :due_date, null: false
        t.integer :status, default: 0
        t.text :purpose
        t.decimal :amount_due, precision: 10, scale: 2
        t.decimal :processing_fee, precision: 10, scale: 2
        t.datetime :approved_at
        t.datetime :disbursed_at
        t.datetime :completed_at
        t.datetime :defaulted_at

        t.timestamps
      end

      add_index :loans, :reference_number, unique: true
      add_index :loans, :status
      add_index :loans, :loan_type
    end

    # Check if loan_repayments table exists
    unless table_exists?(:loan_repayments)
      create_table :loan_repayments do |t|
        t.references :loan, null: false, foreign_key: true
        t.references :transaction, foreign_key: true
        t.decimal :amount, precision: 10, scale: 2, null: false
        t.integer :status, default: 0
        t.datetime :paid_at

        t.timestamps
      end

      add_index :loan_repayments, :status
    end
  end
end

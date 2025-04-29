class AddPortionColumnsToLoanRepayments < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_repayments, :principal_portion, :decimal, precision: 10, scale: 2
    add_column :loan_repayments, :interest_portion, :decimal, precision: 10, scale: 2
    add_column :loan_repayments, :fee_portion, :decimal, precision: 10, scale: 2, default: 0
    add_column :loan_repayments, :remaining_balance, :decimal, precision: 10, scale: 2

    # Update existing records to use the new columns
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE loan_repayments
          SET principal_portion = principal_amount,
              interest_portion = interest_amount
        SQL
      end
    end
  end
end

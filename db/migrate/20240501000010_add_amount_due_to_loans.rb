class AddAmountDueToLoans < ActiveRecord::Migration[8.0]
  def change
    # Add amount_due column if it doesn't exist
    unless column_exists?(:loans, :amount_due)
      add_column :loans, :amount_due, :decimal, precision: 10, scale: 2
    end
  end
end

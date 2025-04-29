class AddRejectionReasonToLoans < ActiveRecord::Migration[8.0]
  def change
    add_column :loans, :rejection_reason, :text
  end
end

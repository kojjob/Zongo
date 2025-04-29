class AddRefinancingFieldsToLoans < ActiveRecord::Migration[7.1]
  def change
    add_reference :loans, :refinanced_from_loan, foreign_key: { to_table: :loans }, null: true
    add_reference :loans, :refinanced_to_loan, foreign_key: { to_table: :loans }, null: true
  end
end

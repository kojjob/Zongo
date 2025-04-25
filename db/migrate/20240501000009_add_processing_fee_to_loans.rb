class AddProcessingFeeToLoans < ActiveRecord::Migration[8.0]
  def change
    # Add processing_fee column if it doesn't exist
    unless column_exists?(:loans, :processing_fee)
      add_column :loans, :processing_fee, :decimal, precision: 10, scale: 2
    end
  end
end

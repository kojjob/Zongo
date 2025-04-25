class AddMetadataToLoans < ActiveRecord::Migration[8.0]
  def change
    # Add metadata column if it doesn't exist
    unless column_exists?(:loans, :metadata)
      add_column :loans, :metadata, :jsonb, default: {}
    end
  end
end

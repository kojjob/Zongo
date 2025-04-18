class AddDescriptionToPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    # Check if the column already exists
    unless column_exists?(:payment_methods, :description)
      add_column :payment_methods, :description, :string, null: true
    end
  end
end

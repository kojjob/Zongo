class AddProductTypeToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :product_type, :string, default: "physical"
    add_column :products, :digital_file_name, :string
    add_column :products, :digital_file_size, :integer
    add_column :products, :digital_content_type, :string
    add_column :products, :download_limit, :integer, default: 0
  end
end

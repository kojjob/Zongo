class AddSellerRoleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :seller, :boolean, default: false
    add_index :users, :seller
  end
end

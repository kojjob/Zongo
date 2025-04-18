class AddProfileFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    # Add new profile fields if they don't exist
    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_column :users, :first_name, :string unless column_exists?(:users, :first_name)
    add_column :users, :last_name, :string unless column_exists?(:users, :last_name)
    add_column :users, :phone_number, :string unless column_exists?(:users, :phone_number)
    add_column :users, :bio, :text unless column_exists?(:users, :bio)
    add_column :users, :date_of_birth, :date unless column_exists?(:users, :date_of_birth)
    add_column :users, :gender, :string unless column_exists?(:users, :gender)
    add_column :users, :address, :string unless column_exists?(:users, :address)
    add_column :users, :city, :string unless column_exists?(:users, :city)
    add_column :users, :state, :string unless column_exists?(:users, :state)
    add_column :users, :country, :string unless column_exists?(:users, :country)
    add_column :users, :postal_code, :string unless column_exists?(:users, :postal_code)
    add_column :users, :website, :string unless column_exists?(:users, :website)
    add_column :users, :occupation, :string unless column_exists?(:users, :occupation)

    # Add indexes for performance if they don't exist
    unless index_exists?(:users, :username)
      add_index :users, :username, unique: true
    end

    unless index_exists?(:users, :phone_number)
      add_index :users, :phone_number, unique: true
    end
  end
end

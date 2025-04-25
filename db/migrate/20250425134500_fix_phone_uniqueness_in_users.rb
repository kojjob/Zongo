class FixPhoneUniquenessInUsers < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing unique index on phone
    remove_index :users, :phone if index_exists?(:users, :phone)
    
    # Change the phone column to allow NULL values
    change_column :users, :phone, :string, null: true, default: nil
    
    # Add a new unique index that ignores NULL values
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL AND phone != ''"
  end
  
  def down
    # Remove the conditional unique index
    remove_index :users, :phone if index_exists?(:users, :phone)
    
    # Change the phone column back to not allow NULL values
    change_column :users, :phone, :string, null: false, default: ""
    
    # Add back the original unique index
    add_index :users, :phone, unique: true
  end
end

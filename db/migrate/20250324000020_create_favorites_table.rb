class CreateFavoritesTable < ActiveRecord::Migration[8.0]
  def change
    # Skip if the table already exists
    return if table_exists?(:favorites)
    
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :favoritable, polymorphic: true, null: false
      
      t.timestamps
    end
    
    add_index :favorites, [:user_id, :favoritable_type, :favoritable_id], unique: true, name: 'index_favorites_on_user_and_favoritable'
  end
end

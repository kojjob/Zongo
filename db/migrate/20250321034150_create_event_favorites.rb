class CreateEventFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :event_favorites do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :event_favorites, [:user_id, :event_id], unique: true
  end
end
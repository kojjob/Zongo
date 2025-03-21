class CreateEventMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :event_media do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :media_type, null: false
      t.string :title
      t.text :description
      t.boolean :is_featured, default: false
      t.integer :display_order
      
      t.timestamps
    end
    
    add_index :event_media, [:event_id, :media_type]
  end
end

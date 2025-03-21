class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.text :short_description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :capacity
      t.integer :status, default: 0
      t.boolean :is_featured, default: false
      t.boolean :is_private, default: false
      t.string :access_code
      t.string :slug, null: false
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.references :event_category, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true
      t.integer :recurrence_type, default: 0
      t.jsonb :recurrence_pattern
      t.references :parent_event, foreign_key: { to_table: :events }
      t.integer :favorites_count, default: 0
      t.integer :views_count, default: 0
      t.jsonb :custom_fields, default: {}
      
      t.timestamps
    end
    
    add_index :events, :slug, unique: true
    add_index :events, :start_time
    add_index :events, :status
    add_index :events, :is_featured
  end
end
class CreateEventTags < ActiveRecord::Migration[8.0]
  def change
    create_table :event_tags do |t|
      t.references :event, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :event_tags, [ :event_id, :tag_id ], unique: true
  end
end

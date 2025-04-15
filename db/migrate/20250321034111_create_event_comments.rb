class CreateEventComments < ActiveRecord::Migration[8.0]
  def change
    create_table :event_comments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent_comment, foreign_key: { to_table: :event_comments }
      t.text :content, null: false
      t.boolean :is_hidden, default: false
      t.integer :likes_count, default: 0

      t.timestamps
    end

    # We'll check if the index exists before adding it
    unless index_exists?(:event_comments, :parent_comment_id)
      add_index :event_comments, :parent_comment_id
    end
  end
end

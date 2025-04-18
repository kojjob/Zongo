class CreateEventViews < ActiveRecord::Migration[7.1]
  def change
    create_table :event_views do |t|
      t.references :event, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true, index: true
      t.string :ip_address, null: false
      t.string :user_agent
      t.string :referrer

      t.timestamps
    end

    add_index :event_views, [ :event_id, :ip_address, :created_at ]

    # Add counter cache to events
    add_column :events, :event_views_count, :integer, default: 0, null: false
  end
end

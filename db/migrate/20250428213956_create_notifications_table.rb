class CreateNotificationsTable < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:notifications)
    
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :message, null: false
      t.integer :severity, default: 0, null: false  # enum: info: 0, warning: 1, critical: 2
      t.integer :category, default: 0, null: false  # enum: general: 0, security: 1, transaction: 2, account: 3, system: 4
      t.boolean :read, default: false, null: false
      t.datetime :read_at
      t.datetime :sent_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :action_url
      t.string :action_text
      t.json :metadata
      t.string :image_url
      t.string :icon

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:user_id, :category]
    add_index :notifications, [:user_id, :severity]
    add_index :notifications, [:user_id, :created_at]
  end
end

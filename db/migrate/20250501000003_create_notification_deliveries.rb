class CreateNotificationDeliveries < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:notification_deliveries)
    
    create_table :notification_deliveries do |t|
      t.references :notification, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.string :status, default: 'pending', null: false  # pending, delivered, failed
      t.datetime :delivered_at
      t.datetime :read_at
      t.text :error_message
      t.integer :attempts, default: 0, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :notification_deliveries, [:notification_id, :notification_channel_id], name: 'index_notification_deliveries_on_notification_and_channel'
    add_index :notification_deliveries, :status
  end
end

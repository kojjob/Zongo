class CreateNotificationChannels < ActiveRecord::Migration[8.0]
  def change
    # Skip if table already exists
    return if table_exists?(:notification_channels)
    
    create_table :notification_channels do |t|
      t.references :user, null: false, foreign_key: true
      t.string :channel_type, null: false  # email, sms, push, etc.
      t.string :identifier, null: false    # email address, phone number, device token, etc.
      t.boolean :enabled, default: true, null: false
      t.boolean :verified, default: false, null: false
      t.datetime :verified_at
      t.string :verification_token
      t.datetime :verification_sent_at
      t.integer :verification_attempts, default: 0, null: false
      t.json :settings
      t.json :metadata

      t.timestamps
    end

    add_index :notification_channels, [:user_id, :channel_type]
    add_index :notification_channels, [:channel_type, :identifier], unique: true
    add_index :notification_channels, :verification_token, unique: true
  end
end

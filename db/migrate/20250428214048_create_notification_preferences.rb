class CreateNotificationPreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :email_enabled, default: true
      t.boolean :sms_enabled, default: true
      t.boolean :push_enabled, default: true
      t.boolean :in_app_enabled, default: true
      t.jsonb :email_preferences, default: {}
      t.jsonb :sms_preferences, default: {}
      t.jsonb :push_preferences, default: {}
      t.jsonb :in_app_preferences, default: {}

      t.timestamps
    end
  end
end

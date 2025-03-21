class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :theme_preference
      t.string :language
      t.string :currency_display
      t.boolean :email_notifications
      t.boolean :sms_notifications
      t.boolean :push_notifications
      t.boolean :deposit_alerts
      t.boolean :withdrawal_alerts
      t.boolean :transfer_alerts
      t.boolean :low_balance_alerts
      t.boolean :login_alerts
      t.boolean :password_alerts
      t.boolean :product_updates
      t.boolean :promotional_emails

      t.timestamps
    end
    add_index :user_settings, [ :user_id, :created_at ]
  end
end

class AddAccessibilityFieldsToUserSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_settings, :text_size, :integer, default: 3
    add_column :user_settings, :reduce_motion, :boolean, default: false
    add_column :user_settings, :high_contrast, :boolean, default: false
  end
end

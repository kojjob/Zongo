class AddIsFreeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :is_free, :boolean, default: false
  end
end

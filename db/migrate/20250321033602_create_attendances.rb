class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :status, default: 0
      t.datetime :checked_in_at
      t.datetime :cancelled_at
      t.text :additional_info
      t.jsonb :form_responses, default: {}
      
      t.timestamps
    end
    
    add_index :attendances, [:user_id, :event_id], unique: true
    add_index :attendances, :status
  end
end
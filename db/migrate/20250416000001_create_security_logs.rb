class CreateSecurityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :security_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :event_type, null: false, default: 0
      t.integer :severity, null: false, default: 0
      t.string :ip_address
      t.string :user_agent
      t.references :loggable, polymorphic: true
      t.jsonb :details, default: {}

      t.timestamps
    end

    add_index :security_logs, [ :user_id, :event_type ]
    add_index :security_logs, [ :user_id, :created_at ]
    add_index :security_logs, :severity
  end
end

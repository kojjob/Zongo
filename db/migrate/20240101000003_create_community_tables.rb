class CreateCommunityTables < ActiveRecord::Migration[7.1]
  def change
    create_table :group_categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.integer :groups_count, default: 0
      t.timestamps
    end

    create_table :groups do |t|
      t.references :group_category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description, null: false
      t.string :image
      t.string :location
      t.boolean :featured, default: false
      t.integer :members_count, default: 0
      t.timestamps
    end

    create_table :group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :role, default: 0
      t.timestamps
    end

    add_index :group_memberships, [:user_id, :group_id], unique: true

    create_table :gatherings do |t|
      t.references :group, foreign_key: true
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description, null: false
      t.date :date, null: false
      t.time :start_time
      t.time :end_time
      t.string :location, null: false
      t.string :image
      t.string :gathering_type
      t.boolean :featured, default: false
      t.integer :attendees_count, default: 0
      t.timestamps
    end

    create_table :gathering_attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :gathering, null: false, foreign_key: true
      t.integer :status, default: 0
      t.timestamps
    end

    add_index :gathering_attendances, [:user_id, :gathering_id], unique: true
  end
end

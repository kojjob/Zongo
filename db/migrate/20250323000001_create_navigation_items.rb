class CreateNavigationItems < ActiveRecord::Migration[7.0]
  def change
    create_table :navigation_items do |t|
      t.string :title, null: false
      t.string :path
      t.string :icon
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.integer :required_role
      t.references :parent, foreign_key: { to_table: :navigation_items }

      t.timestamps
    end
    
    add_index :navigation_items, :position
    add_index :navigation_items, :active
  end
end

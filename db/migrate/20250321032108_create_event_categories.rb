class CreateEventCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :event_categories do |t|
      t.string :name
      t.text :description
      t.string :icon
      t.references :parent_category, null: true, foreign_key: { to_table: :event_categories }

      t.timestamps
    end
    add_index :event_categories, [:parent_category_id, :name], unique: true
  end
end

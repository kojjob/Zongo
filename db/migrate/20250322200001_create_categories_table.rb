class CreateCategoriesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.string :color_code
      t.integer :display_order, default: 0

      t.timestamps
    end
    add_index :categories, :name, unique: true
  end
end
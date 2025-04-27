class CreateShopCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false
      t.string :icon
      t.string :color_code
      t.references :parent, foreign_key: { to_table: :shop_categories }
      t.boolean :featured, default: false
      t.boolean :active, default: true
      t.integer :position, default: 0

      t.timestamps
    end
    
    add_index :shop_categories, :name, unique: true
    add_index :shop_categories, :slug, unique: true
  end
end

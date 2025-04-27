class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :original_price, precision: 10, scale: 2
      t.integer :stock_quantity, default: 0, null: false
      t.string :sku, null: false
      t.references :shop_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.boolean :featured, default: false
      t.string :brand
      t.jsonb :specifications, default: {}
      t.string :tags, array: true, default: []
      t.decimal :weight
      t.string :weight_unit
      t.decimal :length
      t.decimal :width
      t.decimal :height
      t.string :dimension_unit

      t.timestamps
    end
    
    add_index :products, :name
    add_index :products, :sku, unique: true
    add_index :products, :status
    add_index :products, :featured
    add_index :products, :tags, using: :gin
  end
end

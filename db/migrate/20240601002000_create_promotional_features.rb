class CreatePromotionalFeatures < ActiveRecord::Migration[8.0]
  def change
    # Create discounts table
    create_table :discounts do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :value, precision: 10, scale: 2, null: false
      t.string :discount_type, null: false, default: 'percentage' # percentage or fixed_amount
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, default: true
      t.integer :usage_limit
      t.integer :usage_count, default: 0
      t.references :shop_category, foreign_key: true
      t.references :product, foreign_key: true
      t.boolean :featured, default: false

      t.timestamps
    end
    
    # Create coupons table
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.decimal :value, precision: 10, scale: 2, null: false
      t.string :discount_type, null: false, default: 'percentage' # percentage or fixed_amount
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, default: true
      t.integer :usage_limit
      t.integer :usage_count, default: 0
      t.decimal :minimum_order_amount, precision: 10, scale: 2
      t.references :shop_category, foreign_key: true
      t.boolean :first_time_purchase_only, default: false

      t.timestamps
    end
    add_index :coupons, :code, unique: true
    
    # Create flash sales table
    create_table :flash_sales do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :active, default: true
      t.boolean :featured, default: false
      t.string :banner_text
      t.string :banner_color, default: '#FF0000'
      t.string :banner_text_color, default: '#FFFFFF'

      t.timestamps
    end
    
    # Create flash sale items table
    create_table :flash_sale_items do |t|
      t.references :flash_sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :discount_value, precision: 10, scale: 2, null: false
      t.string :discount_type, null: false, default: 'percentage' # percentage or fixed_amount
      t.integer :quantity_limit
      t.integer :sold_count, default: 0

      t.timestamps
    end
    add_index :flash_sale_items, [:flash_sale_id, :product_id], unique: true
    
    # Create promotional banners table
    create_table :promotional_banners do |t|
      t.string :title, null: false
      t.text :description
      t.string :button_text
      t.string :link_url
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, default: true
      t.integer :position, default: 0
      t.string :background_color, default: '#F3F4F6'
      t.string :text_color, default: '#111827'
      t.string :button_color, default: '#4F46E5'
      t.string :button_text_color, default: '#FFFFFF'
      t.string :location, default: 'home' # home, category, product, etc.
      t.references :shop_category, foreign_key: true

      t.timestamps
    end
    
    # Add coupon reference to orders
    add_reference :orders, :coupon, foreign_key: true
    add_column :orders, :coupon_discount, :decimal, precision: 10, scale: 2, default: 0
  end
end

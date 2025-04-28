class CreateDigitalDownloads < ActiveRecord::Migration[7.0]
  def change
    create_table :digital_downloads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true
      t.string :ip_address
      
      t.timestamps
    end
    
    add_index :digital_downloads, [:user_id, :product_id]
  end
end

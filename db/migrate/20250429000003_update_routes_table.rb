class UpdateRoutesTable < ActiveRecord::Migration[8.0]
  def change
    change_table :routes do |t|
      t.references :transport_company, foreign_key: true
      t.integer :duration_minutes
      t.decimal :base_price, precision: 10, scale: 2
      t.string :currency, default: "GHS"
      t.boolean :popular, default: false
      t.boolean :active, default: true
      t.json :schedule
      t.json :amenities
      t.json :metadata
    end
    
    add_index :routes, :popular
    add_index :routes, :active
  end
end

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
    
    # Change string transport_type to integer transport_type with enum if it exists
    if column_exists?(:routes, :transport_type)
      rename_column :routes, :transport_type, :transport_type_string
      add_column :routes, :transport_type, :integer, default: 0
      
      # Add data migration to convert transport_type_string to transport_type integer
      reversible do |dir|
        dir.up do
          execute <<-SQL
            UPDATE routes 
            SET transport_type = CASE 
              WHEN transport_type_string = 'bus' THEN 0
              WHEN transport_type_string = 'train' THEN 1
              WHEN transport_type_string = 'ferry' THEN 2
              WHEN transport_type_string = 'plane' THEN 3
              ELSE 0
            END
          SQL
        end
      end
      
      add_index :routes, :transport_type
    end
  end
end

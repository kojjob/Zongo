class CreateTransportCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :transport_companies do |t|
      t.string :name, null: false
      t.integer :transport_type, default: 0, null: false
      t.string :logo_url
      t.string :website
      t.string :phone
      t.string :email
      t.text :description
      t.boolean :active, default: true
      t.json :amenities
      t.json :metadata

      t.timestamps
    end
    
    add_index :transport_companies, :name, unique: true
    add_index :transport_companies, :transport_type
    add_index :transport_companies, :active
  end
end

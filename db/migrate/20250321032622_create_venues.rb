class CreateVenues < ActiveRecord::Migration[8.0]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.text :description
      t.string :address, null: false
      t.string :city, null: false
      t.string :region
      t.string :postal_code
      t.string :country, default: "Ghana"
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :capacity
      t.jsonb :facilities, default: {}
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :venues, [ :latitude, :longitude ]
    add_index :venues, :city
  end
end

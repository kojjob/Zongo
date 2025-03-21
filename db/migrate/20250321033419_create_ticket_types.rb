class CreateTicketTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_types do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :quantity
      t.datetime :sales_start_time
      t.datetime :sales_end_time
      t.integer :sold_count, default: 0
      t.integer :max_per_user
      t.boolean :transferable, default: true
      
      t.timestamps
    end
  end
end
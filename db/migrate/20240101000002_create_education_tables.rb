class CreateEducationTables < ActiveRecord::Migration[7.1]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.string :school_type
      t.string :contact_email
      t.string :contact_phone
      t.string :website
      t.text :description
      t.string :logo
      t.boolean :featured, default: false
      t.integer :payments_count, default: 0
      t.timestamps
    end

    create_table :school_fee_payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :student_name, null: false
      t.string :student_id, null: false
      t.string :term, null: false
      t.string :payment_method, null: false
      t.string :status, default: "pending"
      t.string :transaction_id
      t.text :notes
      t.timestamps
    end

    create_table :resource_categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.integer :resources_count, default: 0
      t.timestamps
    end

    create_table :learning_resources do |t|
      t.references :resource_category, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.string :file_url, null: false
      t.string :thumbnail
      t.string :file_type
      t.string :level
      t.string :duration
      t.boolean :featured, default: false
      t.integer :downloads_count, default: 0
      t.timestamps
    end
  end
end

class CreateContactSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_submissions do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :subject
      t.text :message

      t.timestamps
    end
    add_index :contact_submissions, :email, unique: true
  end
end

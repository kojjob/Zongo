class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment, null: false
      t.boolean :approved, default: false
      t.text :admin_comment
      t.datetime :approved_at

      t.timestamps
    end
    
    add_index :reviews, [:user_id, :product_id], unique: true
    add_index :reviews, :rating
    add_index :reviews, :approved
  end
end

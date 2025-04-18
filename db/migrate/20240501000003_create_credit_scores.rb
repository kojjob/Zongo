class CreateCreditScores < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_scores do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false
      t.text :factors
      t.datetime :calculated_at

      t.timestamps
    end

    add_index :credit_scores, :score
  end
end

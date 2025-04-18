class AddIsCurrentToCreditScores < ActiveRecord::Migration[8.0]
  def change
    # Check if credit_scores table exists
    unless table_exists?(:credit_scores)
      create_table :credit_scores do |t|
        t.references :user, null: false, foreign_key: true
        t.integer :score, null: false
        t.text :factors
        t.boolean :is_current, default: true
        t.datetime :calculated_at

        t.timestamps
      end

      add_index :credit_scores, :score
      add_index :credit_scores, :is_current
    else
      # Add is_current column if it doesn't exist
      unless column_exists?(:credit_scores, :is_current)
        add_column :credit_scores, :is_current, :boolean, default: true
        add_index :credit_scores, :is_current
      end
    end
  end
end

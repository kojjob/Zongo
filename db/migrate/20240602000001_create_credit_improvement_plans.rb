class CreateCreditImprovementPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_improvement_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :starting_score, null: false
      t.integer :target_score, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :credit_improvement_plans, [:user_id, :status]
  end
end

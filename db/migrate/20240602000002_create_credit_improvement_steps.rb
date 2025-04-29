class CreateCreditImprovementSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_improvement_steps do |t|
      t.references :credit_improvement_plan, null: false, foreign_key: true
      t.string :action, null: false
      t.text :description, null: false
      t.integer :impact, null: false
      t.integer :timeframe, default: 0, null: false
      t.integer :difficulty, default: 0, null: false
      t.integer :category, default: 4, null: false
      t.integer :status, default: 0, null: false
      t.integer :position, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :credit_improvement_steps, [:credit_improvement_plan_id, :position]
    add_index :credit_improvement_steps, [:credit_improvement_plan_id, :status]
  end
end

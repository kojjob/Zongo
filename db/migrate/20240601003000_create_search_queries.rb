class CreateSearchQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :search_queries do |t|
      t.string :query, null: false
      t.references :user, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.integer :results_count, default: 0
      
      t.timestamps
    end
    
    add_index :search_queries, :query
  end
end

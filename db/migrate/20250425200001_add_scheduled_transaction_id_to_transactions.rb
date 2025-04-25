class AddScheduledTransactionIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :scheduled_transaction, foreign_key: true, index: true, null: true
    
    # Update existing transactions that have scheduled_transaction_id in metadata
    execute <<-SQL
      UPDATE transactions
      SET scheduled_transaction_id = (metadata->>'scheduled_transaction_id')::integer
      WHERE metadata->>'scheduled_transaction_id' IS NOT NULL
      AND metadata->>'scheduled_transaction_id' ~ '^[0-9]+$'
    SQL
  end
end

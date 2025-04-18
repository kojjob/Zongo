class AddUserIdToScheduledTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :scheduled_transactions, :user, foreign_key: true, null: true

    # Update existing records to set user_id based on source_wallet's user_id
    execute <<-SQL
      UPDATE scheduled_transactions
      SET user_id = wallets.user_id
      FROM wallets
      WHERE scheduled_transactions.source_wallet_id = wallets.id
    SQL

    # Make user_id not nullable after updating existing records
    change_column_null :scheduled_transactions, :user_id, false
  end
end

class AddBlockedStatusToTransactions < ActiveRecord::Migration[8.0]
  def up
    # Check if status column exists and if there's an existing enum definition
    return if Transaction.defined_enums["status"]&.key?("blocked")

    # Unfortunately, we can't simply add a new enum value in Rails
    # We need to use raw SQL to update the check constraint

    # Get the current enum definition
    enum_types = execute("SELECT enumlabel FROM pg_enum WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'transactions_status');")

    # If the enum type exists and doesn't have 'blocked' value
    if enum_types.count > 0 && !enum_types.any? { |r| r["enumlabel"] == "blocked" }
      execute("ALTER TYPE transactions_status ADD VALUE 'blocked';")
    end

    # If there's no enum type yet, we'll need to add a migration for the whole status column
    # But that should be covered by the existing migrations
  end

  def down
    # We can't remove enum values in PostgreSQL, so this is a no-op
    # If needed, a more complex enum replacement would need to be implemented
  end
end

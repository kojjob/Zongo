# Transaction Isolation for Financial Operations

## Overview

To ensure data integrity and prevent race conditions during financial operations, we've implemented a robust transaction isolation system. This system provides:

1. **Proper database isolation levels** to prevent dirty reads, non-repeatable reads, and phantom reads
2. **Resource locking strategies** to prevent concurrent modifications to the same data
3. **Deadlock prevention** through consistent lock acquisition order
4. **Retry mechanisms** for handling deadlocks and transaction conflicts
5. **Error handling** with appropriate responses

## Components

### TransactionIsolationService

The core of our isolation strategy is implemented in the `TransactionIsolationService` class, which provides:

- Transaction execution with configurable isolation levels
- Wallet locking with deadlock prevention
- Balance operations with proper concurrency control
- Transfer operations between wallets
- Retry mechanisms for resolving conflicts

## Isolation Levels

We use PostgreSQL's transaction isolation levels:

| Level | Description | Use Cases |
|-------|-------------|-----------|
| `READ COMMITTED` | Cannot see uncommitted changes from other transactions | Read operations with minimal locking |
| `REPEATABLE READ` | Ensures same results for repeated reads within a transaction | Operations requiring consistent reads |
| `SERIALIZABLE` | Ensures that transactions execute as if they were serialized one after another | Financial operations with concurrent updates |

For financial operations, we primarily use `SERIALIZABLE` to ensure the highest level of data integrity.

## Locking Strategies

### Row-Level Locking

We use different PostgreSQL locking modes:

1. **FOR UPDATE** - Locks rows for writing
2. **FOR UPDATE NOWAIT** - Locks rows without waiting (fails immediately if lock can't be acquired)
3. **FOR SHARE** - Locks rows for reading only

### Deadlock Prevention

To prevent deadlocks, we:

1. Always acquire locks in a consistent order (by sorting wallet IDs)
2. Use timeouts to detect deadlocks
3. Implement retry strategies to resolve deadlocks

## Implementation in Key Areas

### Wallet Operations

```ruby
# Credit operation in TransactionIsolationService
def update_wallet_balance(wallet, amount, transaction_id = nil)
  transaction(:serializable, lock_for_update: true) do |should_lock|
    # Lock the wallet for update
    locked_wallet = should_lock ? lock_wallet(wallet) : wallet
    
    # Update balance with SQL to ensure atomic update
    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE wallets 
      SET balance = balance + #{ActiveRecord::Base.connection.quote(amount)},
          last_transaction_at = #{ActiveRecord::Base.connection.quote(Time.current)}
      WHERE id = #{ActiveRecord::Base.connection.quote(locked_wallet.id)}
      AND balance + #{ActiveRecord::Base.connection.quote(amount)} >= 0
    SQL
    
    # Reload wallet to get updated balance
    locked_wallet.reload
  end
end
```

### Transfers Between Wallets

```ruby
# Transfer operation in TransactionIsolationService
def transfer_between_wallets(source_wallet, destination_wallet, amount, transaction_id = nil)
  transaction(:serializable, lock_for_update: true) do |should_lock|
    if should_lock
      # Lock both wallets in a consistent order to prevent deadlocks
      locked_wallets = lock_wallets(source_wallet, destination_wallet)
      locked_source = locked_wallets.find { |w| w.id == source_wallet.id }
      locked_destination = locked_wallets.find { |w| w.id == destination_wallet.id }
    else
      locked_source = source_wallet
      locked_destination = destination_wallet
    end
    
    # Perform debit and credit operations atomically
    # ...
  end
end
```

### Transaction Processing

```ruby
# Process a transaction in TransactionService
def process(external_reference: nil, verification_data: {})
  # Validate transaction...
  
  # Use the TransactionIsolationService to process the transaction with proper isolation
  isolation_service = TransactionIsolationService.new
  isolation_service.process_financial_transaction(transaction)
end
```

## Handling Race Conditions

Common race conditions we prevent:

1. **Double-spending** - Concurrent withdrawals exceeding balance
2. **Lost updates** - One transaction overwriting another's changes
3. **Incorrect balance calculations** - Reading stale data during calculations

## Error Handling and Recovery

The system implements:

1. **Automatic retries** for recoverable errors like deadlocks
2. **Exponential backoff** to prevent system overload
3. **Comprehensive logging** for debugging and auditing
4. **Consistent error responses** using the Result pattern

## Testing

To ensure the reliability of our isolation mechanism:

1. Write unit tests for individual components
2. Create integration tests for complete transaction flows
3. Implement stress tests with concurrent operations
4. Monitor for deadlocks and lock timeouts in production

## Best Practices

When implementing new financial operations:

1. **Always use TransactionIsolationService** for database operations
2. **Lock resources before reading or modifying them**
3. **Acquire locks in a consistent order** to prevent deadlocks
4. **Use the highest appropriate isolation level** (usually SERIALIZABLE)
5. **Implement proper error handling and retries**
6. **Log all stages of transaction processing**
7. **Return appropriate Result objects** with success or failure information

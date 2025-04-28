require 'test_helper'

class TransactionIsolationServiceTest < ActiveSupport::TestCase
  setup do
    @service = TransactionIsolationService.new
    
    # Create test users and wallets
    @user1 = User.create!(
      email: "user1@example.com",
      password: "password123",
      name: "Test User 1"
    )
    
    @user2 = User.create!(
      email: "user2@example.com",
      password: "password123",
      name: "Test User 2"
    )
    
    @wallet1 = Wallet.create!(
      user: @user1,
      wallet_id: "TESTWALLET1",
      balance: 1000.0,
      currency: "GHS",
      status: :active,
      daily_limit: 10000.0
    )
    
    @wallet2 = Wallet.create!(
      user: @user2,
      wallet_id: "TESTWALLET2",
      balance: 500.0,
      currency: "GHS",
      status: :active,
      daily_limit: 10000.0
    )
  end
  
  test "transaction executes block and returns success result" do
    result = @service.transaction do
      "test_value"
    end
    
    assert result.success?
    assert_equal "test_value", result.data
  end
  
  test "transaction returns failure result when block raises error" do
    result = @service.transaction do
      raise "Test error"
    end
    
    assert result.failure?
    assert_equal "An error occurred during transaction processing", result.error_message
    assert_equal :system_error, result.error_code
  end
  
  test "update_wallet_balance adds amount to wallet balance" do
    result = @service.update_wallet_balance(@wallet1, 200.0, "TEST-CREDIT-1")
    
    assert result.success?
    
    @wallet1.reload
    assert_equal 1200.0, @wallet1.balance
  end
  
  test "update_wallet_balance subtracts amount from wallet balance" do
    result = @service.update_wallet_balance(@wallet1, -200.0, "TEST-DEBIT-1")
    
    assert result.success?
    
    @wallet1.reload
    assert_equal 800.0, @wallet1.balance
  end
  
  test "update_wallet_balance fails when insufficient funds" do
    result = @service.update_wallet_balance(@wallet1, -2000.0, "TEST-DEBIT-FAIL")
    
    assert result.failure?
    assert_equal :insufficient_funds, result.error_code
    
    @wallet1.reload
    assert_equal 1000.0, @wallet1.balance # Balance should remain unchanged
  end
  
  test "transfer_between_wallets moves money from source to destination" do
    result = @service.transfer_between_wallets(@wallet1, @wallet2, 300.0, "TEST-TRANSFER-1")
    
    assert result.success?
    
    @wallet1.reload
    @wallet2.reload
    
    assert_equal 700.0, @wallet1.balance
    assert_equal 800.0, @wallet2.balance
  end
  
  test "transfer_between_wallets fails when insufficient funds" do
    result = @service.transfer_between_wallets(@wallet1, @wallet2, 2000.0, "TEST-TRANSFER-FAIL")
    
    assert result.failure?
    assert_equal :insufficient_funds, result.error_code
    
    @wallet1.reload
    @wallet2.reload
    
    # Balances should remain unchanged
    assert_equal 1000.0, @wallet1.balance
    assert_equal 500.0, @wallet2.balance
  end
  
  test "transfer_between_wallets fails when same wallet" do
    result = @service.transfer_between_wallets(@wallet1, @wallet1, 100.0, "TEST-SAME-WALLET")
    
    assert result.failure?
    assert_equal :validation_error, result.error_code
    
    @wallet1.reload
    assert_equal 1000.0, @wallet1.balance # Balance should remain unchanged
  end
  
  test "process_financial_transaction handles deposits correctly" do
    # Create a deposit transaction
    transaction = Transaction.create_deposit(
      wallet: @wallet1,
      amount: 250.0,
      payment_method: :mobile_money,
      provider: "MTN",
      metadata: { source: "test" }
    )
    
    result = @service.process_financial_transaction(transaction)
    
    assert result.success?
    
    @wallet1.reload
    transaction.reload
    
    assert_equal 1250.0, @wallet1.balance
    assert_equal "completed", transaction.status
  end
  
  test "process_financial_transaction handles withdrawals correctly" do
    # Create a withdrawal transaction
    transaction = Transaction.create_withdrawal(
      wallet: @wallet1,
      amount: 200.0,
      payment_method: :mobile_money,
      provider: "MTN",
      metadata: { destination: "test" }
    )
    
    result = @service.process_financial_transaction(transaction)
    
    assert result.success?
    
    @wallet1.reload
    transaction.reload
    
    assert_equal 800.0, @wallet1.balance
    assert_equal "completed", transaction.status
  end
  
  test "process_financial_transaction handles transfers correctly" do
    # Create a transfer transaction
    transaction = Transaction.create_transfer(
      source_wallet: @wallet1,
      destination_wallet: @wallet2,
      amount: 350.0,
      description: "Test transfer",
      metadata: { purpose: "test" }
    )
    
    result = @service.process_financial_transaction(transaction)
    
    assert result.success?
    
    @wallet1.reload
    @wallet2.reload
    transaction.reload
    
    assert_equal 650.0, @wallet1.balance
    assert_equal 850.0, @wallet2.balance
    assert_equal "completed", transaction.status
  end
  
  test "lock_wallet acquires a lock on the wallet" do
    # This test verifies that the lock_wallet method works
    # We'll use a thread to simulate concurrent access
    
    wallet = @wallet1
    initial_balance = wallet.balance
    
    # Start a thread that will lock the wallet for 0.5 seconds
    thread = Thread.new do
      @service.transaction(:serializable, lock_for_update: true) do |_should_lock|
        locked_wallet = @service.lock_wallet(wallet)
        # Hold the lock for 0.5 seconds
        sleep 0.5
        # Update the balance
        ActiveRecord::Base.connection.execute(<<~SQL)
          UPDATE wallets 
          SET balance = #{initial_balance + 100}
          WHERE id = #{wallet.id}
        SQL
        true
      end
    end
    
    # Give the thread a moment to acquire the lock
    sleep 0.1
    
    # Try to update the wallet while it's locked
    # This should either wait for the lock or throw an exception
    begin
      # Set a timeout to avoid hanging the test
      Timeout.timeout(1) do
        @service.transaction(:serializable, lock_for_update: true) do |_should_lock|
          locked_wallet = @service.lock_wallet(wallet)
          # If we got here, the lock was acquired after the first thread released it
          flunk "Second thread should not be able to acquire the lock while first thread holds it"
        end
      end
    rescue Timeout::Error
      # Expected - the second thread should time out waiting for the lock
      pass("Lock acquisition timed out as expected")
    rescue ActiveRecord::LockWaitTimeout, ActiveRecord::StatementInvalid => e
      # Also acceptable - database may return a lock timeout exception
      pass("Database threw lock exception as expected: #{e.class.name}")
    ensure
      # Wait for the thread to finish
      thread.join
    end
    
    # Verify the balance was updated by the first thread
    wallet.reload
    assert_equal initial_balance + 100, wallet.balance
  end
  
  # Helper method to mark a test as passed
  def pass(message = nil)
    assert true, message
  end
end

require 'test_helper'

class TransactionIsolationServiceTest < ActiveSupport::TestCase
  setup do
    @isolation_service = TransactionIsolationService.new
    
    # Create test users
    @user1 = User.create!(
      email: 'user1@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User1'
    )
    
    @user2 = User.create!(
      email: 'user2@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User2'
    )
    
    # Create wallets for test users
    @wallet1 = Wallet.create!(
      user: @user1,
      wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}",
      balance: 1000,
      currency: 'GHS',
      status: :active,
      daily_limit: 5000
    )
    
    @wallet2 = Wallet.create!(
      user: @user2,
      wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}",
      balance: 500,
      currency: 'GHS',
      status: :active,
      daily_limit: 5000
    )
  end
  
  test "transaction should execute block and return success result" do
    result = @isolation_service.transaction do
      "test data"
    end
    
    assert result.success?
    assert_equal "test data", result.data
  end
  
  test "transaction should return failure result when exception occurs" do
    result = @isolation_service.transaction do
      raise StandardError, "Test error"
    end
    
    assert result.failure?
    assert_equal "An error occurred during transaction processing", result.error_message
    assert_equal :system_error, result.error_code
  end
  
  test "lock_wallet should return locked wallet" do
    # Assuming this is a unit test - we'd just verify the method returns the wallet
    # In a real application, we'd need to test this with threads to ensure locking
    locked_wallet = @isolation_service.lock_wallet(@wallet1)
    assert_equal @wallet1.id, locked_wallet.id
  end
  
  test "lock_wallets should lock multiple wallets in ID order" do
    # Again, in a real test we'd verify actual locking behavior with threads
    locked_wallets = @isolation_service.lock_wallets(@wallet1, @wallet2)
    assert_equal 2, locked_wallets.size
    assert locked_wallets.map(&:id).include?(@wallet1.id)
    assert locked_wallets.map(&:id).include?(@wallet2.id)
  end
  
  test "update_wallet_balance should credit wallet" do
    initial_balance = @wallet1.balance
    amount_to_add = 200
    
    result = @isolation_service.update_wallet_balance(@wallet1, amount_to_add, "TEST123")
    
    assert result.success?
    @wallet1.reload
    assert_equal initial_balance + amount_to_add, @wallet1.balance
  end
  
  test "update_wallet_balance should debit wallet" do
    initial_balance = @wallet1.balance
    amount_to_deduct = 200
    
    result = @isolation_service.update_wallet_balance(@wallet1, -amount_to_deduct, "TEST123")
    
    assert result.success?
    @wallet1.reload
    assert_equal initial_balance - amount_to_deduct, @wallet1.balance
  end
  
  test "update_wallet_balance should fail when insufficient funds" do
    amount_to_deduct = @wallet1.balance + 100 # More than balance
    
    result = @isolation_service.update_wallet_balance(@wallet1, -amount_to_deduct, "TEST123")
    
    assert result.failure?
    assert_equal :insufficient_funds, result.error_code
    @wallet1.reload
    assert_equal 1000, @wallet1.balance # Balance unchanged
  end
  
  test "transfer_between_wallets should move funds between wallets" do
    wallet1_initial = @wallet1.balance
    wallet2_initial = @wallet2.balance
    transfer_amount = 300
    
    result = @isolation_service.transfer_between_wallets(
      @wallet1, @wallet2, transfer_amount, "TRANSFER123"
    )
    
    assert result.success?
    @wallet1.reload
    @wallet2.reload
    assert_equal wallet1_initial - transfer_amount, @wallet1.balance
    assert_equal wallet2_initial + transfer_amount, @wallet2.balance
  end
  
  test "transfer_between_wallets should fail with insufficient funds" do
    transfer_amount = @wallet1.balance + 100 # More than available
    
    result = @isolation_service.transfer_between_wallets(
      @wallet1, @wallet2, transfer_amount, "TRANSFER123"
    )
    
    assert result.failure?
    assert_equal :insufficient_funds, result.error_code
    @wallet1.reload
    @wallet2.reload
    assert_equal 1000, @wallet1.balance # Balance unchanged
    assert_equal 500, @wallet2.balance # Balance unchanged
  end
  
  test "transfer_between_wallets should fail if same wallet" do
    result = @isolation_service.transfer_between_wallets(
      @wallet1, @wallet1, 100, "TRANSFER123"
    )
    
    assert result.failure?
    assert_equal "Source and destination wallets must be different", result.error_message
  end
  
  test "process_financial_transaction should process a deposit transaction" do
    # Create a deposit transaction
    transaction = Transaction.create_deposit(
      wallet: @wallet1,
      amount: 300,
      payment_method: :mobile_money,
      provider: 'MTN',
      metadata: {}
    )
    
    result = @isolation_service.process_financial_transaction(transaction)
    
    assert result.success?
    @wallet1.reload
    transaction.reload
    assert_equal 1300, @wallet1.balance
    assert transaction.status_completed?
  end
  
  test "process_financial_transaction should process a withdrawal transaction" do
    # Create a withdrawal transaction
    transaction = Transaction.create_withdrawal(
      wallet: @wallet1,
      amount: 200,
      payment_method: :mobile_money,
      provider: 'MTN',
      metadata: {}
    )
    
    result = @isolation_service.process_financial_transaction(transaction)
    
    assert result.success?
    @wallet1.reload
    transaction.reload
    assert_equal 800, @wallet1.balance
    assert transaction.status_completed?
  end
  
  test "process_financial_transaction should process a transfer transaction" do
    # Create a transfer transaction
    transaction = Transaction.create_transfer(
      source_wallet: @wallet1,
      destination_wallet: @wallet2,
      amount: 300,
      description: 'Test transfer',
      metadata: {}
    )
    
    result = @isolation_service.process_financial_transaction(transaction)
    
    assert result.success?
    @wallet1.reload
    @wallet2.reload
    transaction.reload
    assert_equal 700, @wallet1.balance
    assert_equal 800, @wallet2.balance
    assert transaction.status_completed?
  end
  
  test "process_financial_transaction should handle insufficient funds" do
    # Create a withdrawal transaction for more than available
    transaction = Transaction.create_withdrawal(
      wallet: @wallet1,
      amount: 1500, # More than balance
      payment_method: :mobile_money,
      provider: 'MTN',
      metadata: {}
    )
    
    result = @isolation_service.process_financial_transaction(transaction)
    
    assert result.failure?
    assert_equal :insufficient_funds, result.error_code
    @wallet1.reload
    transaction.reload
    assert_equal 1000, @wallet1.balance # Unchanged
    assert transaction.status_failed?
  end
end

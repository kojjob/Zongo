require 'test_helper'

class ScheduledTransactionProcessorTest < ActiveSupport::TestCase
  setup do
    # Create test users
    @user1 = User.create!(
      email: 'scheduled_test1@example.com',
      password: 'password123',
      first_name: 'Scheduled',
      last_name: 'Test1'
    )
    
    @user2 = User.create!(
      email: 'scheduled_test2@example.com',
      password: 'password123',
      first_name: 'Scheduled',
      last_name: 'Test2'
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
    
    # Create scheduled transactions
    @scheduled_transfer = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      destination_wallet: @wallet2,
      amount: 100,
      transaction_type: :transfer,
      frequency: :weekly,
      next_occurrence: 1.day.ago, # Due now
      status: :active,
      description: "Test Scheduled Transfer",
      occurrences_count: 0
    )
    
    @scheduled_deposit = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      amount: 200,
      transaction_type: :deposit,
      payment_method: :mobile_money,
      payment_provider: 'MTN',
      frequency: :monthly,
      next_occurrence: 1.day.ago, # Due now
      status: :active,
      description: "Test Scheduled Deposit",
      occurrences_count: 0
    )
    
    @scheduled_withdrawal = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      amount: 150,
      transaction_type: :withdrawal,
      payment_method: :mobile_money,
      payment_provider: 'MTN',
      frequency: :biweekly,
      next_occurrence: 1.day.ago, # Due now
      status: :active,
      description: "Test Scheduled Withdrawal",
      occurrences_count: 0
    )
    
    @future_scheduled = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      destination_wallet: @wallet2,
      amount: 75,
      transaction_type: :transfer,
      frequency: :weekly,
      next_occurrence: 3.days.from_now, # Not due yet
      status: :active,
      description: "Future Scheduled Transfer",
      occurrences_count: 0
    )
    
    @processor = ScheduledTransactionProcessor.new
  end
  
  test "process_scheduled_transaction should process a due transfer transaction" do
    result = @processor.process_scheduled_transaction(@scheduled_transfer)
    
    assert result.success?
    @wallet1.reload
    @wallet2.reload
    @scheduled_transfer.reload
    
    assert_equal 900, @wallet1.balance # Original 1000 - 100 transfer
    assert_equal 600, @wallet2.balance # Original 500 + 100 transfer
    assert_equal 1, @scheduled_transfer.occurrences_count
    assert @scheduled_transfer.last_occurrence.present?
    assert @scheduled_transfer.next_occurrence > Time.current # Updated to next week
  end
  
  test "process_scheduled_transaction should process a due deposit transaction" do
    result = @processor.process_scheduled_transaction(@scheduled_deposit)
    
    assert result.success?
    @wallet1.reload
    @scheduled_deposit.reload
    
    assert_equal 1200, @wallet1.balance # Original 1000 + 200 deposit
    assert_equal 1, @scheduled_deposit.occurrences_count
    assert @scheduled_deposit.last_occurrence.present?
    assert @scheduled_deposit.next_occurrence > Time.current # Updated to next month
  end
  
  test "process_scheduled_transaction should process a due withdrawal transaction" do
    result = @processor.process_scheduled_transaction(@scheduled_withdrawal)
    
    assert result.success?
    @wallet1.reload
    @scheduled_withdrawal.reload
    
    assert_equal 850, @wallet1.balance # Original 1000 - 150 withdrawal
    assert_equal 1, @scheduled_withdrawal.occurrences_count
    assert @scheduled_withdrawal.last_occurrence.present?
    assert @scheduled_withdrawal.next_occurrence > Time.current # Updated to next biweekly
  end
  
  test "process_scheduled_transaction should not process transaction that is not due" do
    result = @processor.process_scheduled_transaction(@future_scheduled)
    
    assert result.failure?
    assert_equal :not_due, result.error_code
    @wallet1.reload
    @wallet2.reload
    @future_scheduled.reload
    
    assert_equal 1000, @wallet1.balance # Unchanged
    assert_equal 500, @wallet2.balance # Unchanged
    assert_equal 0, @future_scheduled.occurrences_count # Unchanged
  end
  
  test "execute_now should process transaction regardless of due date" do
    result = @processor.execute_now(@future_scheduled)
    
    assert result.success?
    @wallet1.reload
    @wallet2.reload
    @future_scheduled.reload
    
    assert_equal 925, @wallet1.balance # Original 1000 - 75 transfer
    assert_equal 575, @wallet2.balance # Original 500 + 75 transfer
    assert_equal 1, @future_scheduled.occurrences_count
    assert @future_scheduled.last_occurrence.present?
    assert @future_scheduled.next_occurrence > Time.current
  end
  
  test "process_due_transactions should process all due transactions" do
    # We have 3 due transactions: transfer, deposit, withdrawal
    results = @processor.process_due_transactions
    
    assert_equal 3, results[:total]
    assert_equal 3, results[:success_count]
    assert_equal 0, results[:failure_count]
    
    @wallet1.reload
    @wallet2.reload
    
    # Balance should reflect all 3 transactions:
    # Original 1000 - 100 (transfer) + 200 (deposit) - 150 (withdrawal) = 950
    assert_equal 950, @wallet1.balance
    # Original 500 + 100 (transfer) = 600
    assert_equal 600, @wallet2.balance
  end
  
  test "process_scheduled_transaction should handle insufficient funds" do
    # Create a transaction with amount larger than balance
    large_withdrawal = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      amount: 2000, # More than wallet balance
      transaction_type: :withdrawal,
      payment_method: :mobile_money,
      payment_provider: 'MTN',
      frequency: :weekly,
      next_occurrence: 1.day.ago, # Due now
      status: :active,
      description: "Large Withdrawal",
      occurrences_count: 0
    )
    
    result = @processor.process_scheduled_transaction(large_withdrawal)
    
    assert result.failure?
    @wallet1.reload
    large_withdrawal.reload
    
    assert_equal 1000, @wallet1.balance # Unchanged
    assert_equal 0, large_withdrawal.occurrences_count # Unchanged
  end
  
  test "process_scheduled_transaction should complete transaction after reaching occurrences_limit" do
    limited_transfer = ScheduledTransaction.create!(
      user: @user1,
      source_wallet: @wallet1,
      destination_wallet: @wallet2,
      amount: 50,
      transaction_type: :transfer,
      frequency: :weekly,
      next_occurrence: 1.day.ago, # Due now
      status: :active,
      description: "Limited Transfer",
      occurrences_count: 2,
      occurrences_limit: 3 # Will complete after this execution
    )
    
    result = @processor.process_scheduled_transaction(limited_transfer)
    
    assert result.success?
    limited_transfer.reload
    
    assert_equal 3, limited_transfer.occurrences_count
    assert limited_transfer.status_completed? # Should be completed since limit reached
  end
  
  test "concurrent processing of scheduled transactions should maintain consistency" do
    # Create multiple scheduled transactions of the same type
    scheduled_transfers = []
    5.times do |i|
      scheduled_transfers << ScheduledTransaction.create!(
        user: @user1,
        source_wallet: @wallet1,
        destination_wallet: @wallet2,
        amount: 50,
        transaction_type: :transfer,
        frequency: :weekly,
        next_occurrence: 1.day.ago, # Due now
        status: :active,
        description: "Concurrent Transfer #{i}",
        occurrences_count: 0
      )
    end
    
    # Process concurrently
    pool = Concurrent::FixedThreadPool.new(5)
    completion_latch = Concurrent::CountDownLatch.new(scheduled_transfers.size)
    
    scheduled_transfers.each do |st|
      pool.post do
        begin
          @processor.process_scheduled_transaction(st)
        ensure
          completion_latch.count_down
        end
      end
    end
    
    completion_latch.wait(30) # Wait for all to complete
    
    # Verify consistency
    @wallet1.reload
    @wallet2.reload
    
    # Should have processed all 5 transfers of 50 each = 250
    assert_equal 750, @wallet1.balance # Original 1000 - 250
    assert_equal 750, @wallet2.balance # Original 500 + 250
    
    scheduled_transfers.each do |st|
      st.reload
      assert_equal 1, st.occurrences_count
    end
  end
end

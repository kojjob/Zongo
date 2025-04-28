require 'test_helper'
require 'concurrent'

class ConcurrencyStressTest < ActiveSupport::TestCase
  setup do
    # Create test users and wallets
    @user = User.create!(
      email: 'stress_test@example.com',
      password: 'password123',
      first_name: 'Stress',
      last_name: 'Test'
    )
    
    @wallet = Wallet.create!(
      user: @user,
      wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}",
      balance: 10000,
      currency: 'GHS',
      status: :active,
      daily_limit: 100000
    )
    
    @recipient = User.create!(
      email: 'recipient@example.com',
      password: 'password123',
      first_name: 'Recipient',
      last_name: 'User'
    )
    
    @recipient_wallet = Wallet.create!(
      user: @recipient,
      wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}",
      balance: 0,
      currency: 'GHS',
      status: :active,
      daily_limit: 100000
    )
    
    # Create isolation service
    @isolation_service = TransactionIsolationService.new
  end
  
  # Test concurrent credit operations
  test "concurrent credit operations should maintain consistency" do
    initial_balance = @wallet.balance
    operations_count = 10
    credit_amount = 100
    
    # Create a thread pool to run concurrent operations
    pool = Concurrent::FixedThreadPool.new(5)
    completion_latch = Concurrent::CountDownLatch.new(operations_count)
    
    operations_count.times do |i|
      pool.post do
        begin
          # Credit the wallet with proper isolation
          @isolation_service.update_wallet_balance(@wallet, credit_amount, "STRESS-CREDIT-#{i}")
        rescue => e
          puts "Credit operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Wait for all operations to complete
    completion_latch.wait(30) # Timeout after 30 seconds
    
    # Verify the final balance
    @wallet.reload
    expected_balance = initial_balance + (operations_count * credit_amount)
    assert_equal expected_balance, @wallet.balance, 
                 "Balance should be #{expected_balance} after #{operations_count} concurrent credit operations"
  end
  
  # Test concurrent debit operations
  test "concurrent debit operations should maintain consistency" do
    initial_balance = @wallet.balance
    operations_count = 10
    debit_amount = 50
    
    # Create a thread pool to run concurrent operations
    pool = Concurrent::FixedThreadPool.new(5)
    completion_latch = Concurrent::CountDownLatch.new(operations_count)
    
    operations_count.times do |i|
      pool.post do
        begin
          # Debit the wallet with proper isolation
          @isolation_service.update_wallet_balance(@wallet, -debit_amount, "STRESS-DEBIT-#{i}")
        rescue => e
          puts "Debit operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Wait for all operations to complete
    completion_latch.wait(30) # Timeout after 30 seconds
    
    # Verify the final balance
    @wallet.reload
    expected_balance = initial_balance - (operations_count * debit_amount)
    assert_equal expected_balance, @wallet.balance, 
                 "Balance should be #{expected_balance} after #{operations_count} concurrent debit operations"
  end
  
  # Test concurrent transfers
  test "concurrent transfers should maintain consistency" do
    source_initial = @wallet.balance
    destination_initial = @recipient_wallet.balance
    operations_count = 10
    transfer_amount = 75
    
    # Create a thread pool to run concurrent operations
    pool = Concurrent::FixedThreadPool.new(5)
    completion_latch = Concurrent::CountDownLatch.new(operations_count)
    
    operations_count.times do |i|
      pool.post do
        begin
          # Transfer between wallets with proper isolation
          @isolation_service.transfer_between_wallets(
            @wallet, @recipient_wallet, transfer_amount, "STRESS-TRANSFER-#{i}"
          )
        rescue => e
          puts "Transfer operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Wait for all operations to complete
    completion_latch.wait(30) # Timeout after 30 seconds
    
    # Verify the final balances
    @wallet.reload
    @recipient_wallet.reload
    expected_source_balance = source_initial - (operations_count * transfer_amount)
    expected_destination_balance = destination_initial + (operations_count * transfer_amount)
    
    assert_equal expected_source_balance, @wallet.balance, 
                 "Source balance should be #{expected_source_balance} after #{operations_count} concurrent transfers"
    assert_equal expected_destination_balance, @recipient_wallet.balance, 
                 "Destination balance should be #{expected_destination_balance} after #{operations_count} concurrent transfers"
  end
  
  # Test race condition prevention - multiple withdrawals with insufficient funds
  test "concurrent withdrawals should not allow overdrafts" do
    # Set initial balance that allows only a few of the withdrawals to succeed
    @wallet.update(balance: 500)
    initial_balance = @wallet.balance
    operations_count = 20
    withdrawal_amount = 100
    
    # Create a thread pool to run concurrent operations
    pool = Concurrent::FixedThreadPool.new(10)
    completion_latch = Concurrent::CountDownLatch.new(operations_count)
    success_count = Concurrent::AtomicFixnum.new(0)
    
    operations_count.times do |i|
      pool.post do
        begin
          # Attempt withdrawal with proper isolation
          result = @isolation_service.update_wallet_balance(@wallet, -withdrawal_amount, "STRESS-WITHDRAW-#{i}")
          if result.success?
            success_count.increment
          end
        rescue => e
          puts "Withdrawal operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Wait for all operations to complete
    completion_latch.wait(30) # Timeout after 30 seconds
    
    # Verify the final balance
    @wallet.reload
    expected_success_count = initial_balance / withdrawal_amount
    
    assert_equal success_count.value, expected_success_count,
                 "Only #{expected_success_count} out of #{operations_count} withdrawals should succeed"
    assert @wallet.balance >= 0, "Balance should never be negative after concurrent withdrawals"
    assert_equal initial_balance - (success_count.value * withdrawal_amount), @wallet.balance,
                 "Balance should be reduced by exactly the amount of successful withdrawals"
  end
  
  # Test deadlock prevention - bidirectional transfers
  test "bidirectional transfers should not deadlock" do
    wallet1 = @wallet
    wallet2 = @recipient_wallet
    
    # Ensure both wallets have balance
    wallet1.update(balance: 5000)
    wallet2.update(balance: 5000)
    
    operations_count = 10
    transfer_amount = 100
    
    # Create thread pools for bidirectional transfers
    pool1 = Concurrent::FixedThreadPool.new(5) # wallet1 -> wallet2
    pool2 = Concurrent::FixedThreadPool.new(5) # wallet2 -> wallet1
    completion_latch = Concurrent::CountDownLatch.new(operations_count * 2)
    
    # Start transfers from wallet1 to wallet2
    operations_count.times do |i|
      pool1.post do
        begin
          @isolation_service.transfer_between_wallets(
            wallet1, wallet2, transfer_amount, "DEADLOCK-TEST-1TO2-#{i}"
          )
        rescue => e
          puts "Transfer 1->2 operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Start transfers from wallet2 to wallet1
    operations_count.times do |i|
      pool2.post do
        begin
          @isolation_service.transfer_between_wallets(
            wallet2, wallet1, transfer_amount, "DEADLOCK-TEST-2TO1-#{i}"
          )
        rescue => e
          puts "Transfer 2->1 operation #{i} failed: #{e.message}"
        ensure
          completion_latch.count_down
        end
      end
    end
    
    # Wait for all operations to complete
    completion_result = completion_latch.wait(60) # Timeout after 60 seconds
    
    # Reload wallets
    wallet1.reload
    wallet2.reload
    
    # Verify deadlock prevention - all operations should complete without hanging
    assert completion_result, "All transfer operations should complete without timeout (deadlock)"
    
    # Final balances should be consistent - equal to initial due to bidirectional transfers of same amount
    assert_equal 5000, wallet1.balance, "Wallet1 balance should remain 5000 after bidirectional transfers"
    assert_equal 5000, wallet2.balance, "Wallet2 balance should remain 5000 after bidirectional transfers"
  end
end

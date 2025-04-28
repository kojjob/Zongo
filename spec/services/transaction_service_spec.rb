require 'rails_helper'

RSpec.describe TransactionService do
  let(:user) { create(:user) }
  let(:recipient) { create(:user) }
  let(:source_wallet) { create(:wallet, user: user, balance: 1000) }
  let(:destination_wallet) { create(:wallet, user: recipient) }

  describe '.create_transfer' do
    it 'creates a valid transfer transaction' do
      result = TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: 100,
        description: 'Test transfer'
      )

      expect(result).to be_success
      expect(result.data[:transaction]).to be_a(Transaction)
      expect(result.data[:transaction].amount).to eq(100)
      expect(result.data[:transaction].source_wallet).to eq(source_wallet)
      expect(result.data[:transaction].destination_wallet).to eq(destination_wallet)
      expect(result.data[:transaction].description).to eq('Test transfer')
      expect(result.data[:transaction].status).to eq('pending')
    end

    it 'returns a failure if source wallet has insufficient funds' do
      result = TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: 2000,
        description: 'Test transfer'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:insufficient_funds)
    end

    it 'returns a failure if source wallet is not active' do
      source_wallet.update(status: :suspended)

      result = TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: 100,
        description: 'Test transfer'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:inactive_source)
    end

    it 'returns a failure if destination wallet is not active' do
      destination_wallet.update(status: :suspended)

      result = TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: 100,
        description: 'Test transfer'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:inactive_destination)
    end

    it 'returns a failure if amount is zero or negative' do
      result = TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: 0,
        description: 'Test transfer'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:invalid_amount)
    end
  end

  describe '.create_deposit' do
    it 'creates a valid deposit transaction' do
      result = TransactionService.create_deposit(
        wallet: destination_wallet,
        amount: 100,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_success
      expect(result.data[:transaction]).to be_a(Transaction)
      expect(result.data[:transaction].amount).to eq(100)
      expect(result.data[:transaction].destination_wallet).to eq(destination_wallet)
      expect(result.data[:transaction].payment_method).to eq('mobile_money')
      expect(result.data[:transaction].provider).to eq('mtn')
      expect(result.data[:transaction].status).to eq('pending')
    end

    it 'returns a failure if amount is zero or negative' do
      result = TransactionService.create_deposit(
        wallet: destination_wallet,
        amount: 0,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:invalid_amount)
    end

    it 'returns a failure if wallet is not active' do
      destination_wallet.update(status: :suspended)

      result = TransactionService.create_deposit(
        wallet: destination_wallet,
        amount: 100,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:inactive_wallet)
    end
  end

  describe '.create_withdrawal' do
    it 'creates a valid withdrawal transaction' do
      result = TransactionService.create_withdrawal(
        wallet: source_wallet,
        amount: 100,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_success
      expect(result.data[:transaction]).to be_a(Transaction)
      expect(result.data[:transaction].amount).to eq(100)
      expect(result.data[:transaction].source_wallet).to eq(source_wallet)
      expect(result.data[:transaction].payment_method).to eq('mobile_money')
      expect(result.data[:transaction].provider).to eq('mtn')
      expect(result.data[:transaction].status).to eq('pending')
    end

    it 'returns a failure if amount is zero or negative' do
      result = TransactionService.create_withdrawal(
        wallet: source_wallet,
        amount: 0,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:invalid_amount)
    end

    it 'returns a failure if wallet has insufficient funds' do
      result = TransactionService.create_withdrawal(
        wallet: source_wallet,
        amount: 2000,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:insufficient_funds)
    end

    it 'returns a failure if wallet is not active' do
      source_wallet.update(status: :suspended)

      result = TransactionService.create_withdrawal(
        wallet: source_wallet,
        amount: 100,
        payment_method: :mobile_money,
        provider: 'mtn'
      )

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:inactive_wallet)
    end
  end

  describe '.find_by_id' do
    let(:transaction) { create(:transaction, source_wallet: source_wallet, destination_wallet: destination_wallet) }

    it 'returns a transaction by ID' do
      result = TransactionService.find_by_id(transaction.id)

      expect(result).to be_success
      expect(result.data[:transaction]).to eq(transaction)
    end

    it 'returns a failure if transaction is not found' do
      result = TransactionService.find_by_id(0)

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:not_found)
    end
  end

  describe '.find_by_transaction_id' do
    let(:transaction) { create(:transaction, source_wallet: source_wallet, destination_wallet: destination_wallet) }

    it 'returns a transaction by transaction_id' do
      result = TransactionService.find_by_transaction_id(transaction.transaction_id)

      expect(result).to be_success
      expect(result.data[:transaction]).to eq(transaction)
    end

    it 'returns a failure if transaction is not found' do
      result = TransactionService.find_by_transaction_id('INVALID')

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:not_found)
    end
  end

  describe '#process' do
    let(:transaction) { create(:transaction, transaction_type: 'transfer', source_wallet: source_wallet, destination_wallet: destination_wallet, amount: 100, status: 'pending') }
    let(:service) { TransactionService.new(transaction, user, '127.0.0.1', 'test') }

    it 'processes a transfer transaction successfully' do
      # Mock the security check to return true
      allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)
      
      # Mock the complete! method to return true
      allow_any_instance_of(Transaction).to receive(:complete!).and_return(true)
      
      # Mock send_transaction_notification to avoid notification issues
      allow_any_instance_of(TransactionService).to receive(:send_transaction_notification).and_return(true)

      result = service.process

      expect(result).to be_success
      expect(result.data[:message]).to eq('Transfer processed successfully')
    end

    it 'returns failure if transaction security check fails' do
      # Mock the security check to return false
      allow_any_instance_of(Transaction).to receive(:security_check).and_return(false)

      result = service.process

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:security_check_failed)
    end

    it 'returns failure if transaction completion fails' do
      # Mock the security check to return true
      allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)
      
      # Mock the complete! method to return false
      allow_any_instance_of(Transaction).to receive(:complete!).and_return(false)

      result = service.process

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:completion_failed)
    end

    it 'handles source wallet with insufficient funds' do
      # Create a transaction with amount greater than wallet balance
      large_transaction = create(:transaction, transaction_type: 'transfer', source_wallet: source_wallet, destination_wallet: destination_wallet, amount: 5000, status: 'pending')
      large_service = TransactionService.new(large_transaction, user, '127.0.0.1', 'test')
      
      # Mock the security check to return true
      allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)

      result = large_service.process

      expect(result).to be_failure
      expect(result.error[:code]).to eq(:insufficient_funds)
    end
  end
end

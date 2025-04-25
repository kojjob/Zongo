require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      transaction = build(:transaction, :deposit)
      expect(transaction).to be_valid
    end
    
    it 'is not valid without a transaction_id' do
      transaction = build(:transaction, :deposit, transaction_id: nil)
      expect(transaction).not_to be_valid
    end
    
    it 'is not valid without a transaction_type' do
      transaction = build(:transaction, :deposit)
      transaction.transaction_type = nil
      expect(transaction).not_to be_valid
    end
    
    it 'is not valid without a status' do
      transaction = build(:transaction, :deposit)
      transaction.status = nil
      expect(transaction).not_to be_valid
    end
    
    it 'is not valid without an amount' do
      transaction = build(:transaction, :deposit, amount: nil)
      expect(transaction).not_to be_valid
    end
    
    it 'is not valid with a negative amount' do
      transaction = build(:transaction, :deposit, amount: -100)
      expect(transaction).not_to be_valid
    end
    
    it 'is not valid without a currency' do
      transaction = build(:transaction, :deposit, currency: nil)
      expect(transaction).not_to be_valid
    end
    
    it 'validates wallet associations based on transaction type' do
      # Deposit requires destination wallet
      deposit = build(:transaction, transaction_type: :deposit, destination_wallet: nil)
      expect(deposit).not_to be_valid
      expect(deposit.errors[:destination_wallet]).to include("must be present for deposits")
      
      # Withdrawal requires source wallet
      withdrawal = build(:transaction, transaction_type: :withdrawal, source_wallet: nil)
      expect(withdrawal).not_to be_valid
      expect(withdrawal.errors[:source_wallet]).to include("must be present for withdrawals")
      
      # Transfer requires both source and destination wallets
      transfer = build(:transaction, transaction_type: :transfer, source_wallet: nil, destination_wallet: nil)
      expect(transfer).not_to be_valid
      expect(transfer.errors[:source_wallet]).to include("must be present for transfers and payments")
      expect(transfer.errors[:destination_wallet]).to include("must be present for transfers and payments")
      
      # Source and destination wallets cannot be the same
      wallet = create(:wallet)
      same_wallet_transfer = build(:transaction, transaction_type: :transfer, 
                                  source_wallet: wallet, destination_wallet: wallet)
      expect(same_wallet_transfer).not_to be_valid
      expect(same_wallet_transfer.errors[:base]).to include("Source and destination wallets cannot be the same")
    end
  end
  
  describe 'callbacks' do
    it 'generates a transaction_id before validation on create' do
      transaction = build(:transaction, :deposit, transaction_id: nil)
      transaction.valid?
      expect(transaction.transaction_id).not_to be_nil
    end
    
    it 'sets default timestamps based on status' do
      pending_transaction = create(:transaction, :deposit)
      expect(pending_transaction.initiated_at).not_to be_nil
      
      completed_transaction = create(:transaction, :deposit, :completed, completed_at: nil)
      expect(completed_transaction.completed_at).not_to be_nil
      
      failed_transaction = create(:transaction, :deposit, :failed, failed_at: nil)
      expect(failed_transaction.failed_at).not_to be_nil
      
      reversed_transaction = create(:transaction, :deposit, :reversed, reversed_at: nil)
      expect(reversed_transaction.reversed_at).not_to be_nil
    end
  end
  
  describe 'scopes' do
    before do
      @completed = create(:transaction, :deposit, :completed)
      @pending = create(:transaction, :deposit)
      @failed = create(:transaction, :deposit, :failed)
      @blocked = create(:transaction, :deposit, :blocked)
      @old_transaction = create(:transaction, :deposit, :completed, created_at: 2.days.ago)
    end
    
    it 'returns successful transactions' do
      expect(Transaction.successful).to include(@completed)
      expect(Transaction.successful).not_to include(@pending, @failed, @blocked)
    end
    
    it 'returns pending or failed transactions' do
      expect(Transaction.pending_or_failed).to include(@pending, @failed)
      expect(Transaction.pending_or_failed).not_to include(@completed, @blocked)
    end
    
    it 'returns recent transactions in descending order' do
      expect(Transaction.recent.first).to eq(@blocked) # Most recent
      expect(Transaction.recent.last).to eq(@old_transaction) # Oldest
    end
    
    it 'returns transactions by date range' do
      expect(Transaction.by_date_range(1.day.ago, Time.current)).to include(@completed, @pending, @failed, @blocked)
      expect(Transaction.by_date_range(1.day.ago, Time.current)).not_to include(@old_transaction)
    end
    
    it 'returns blocked transactions' do
      expect(Transaction.blocked).to include(@blocked)
      expect(Transaction.blocked).not_to include(@completed, @pending, @failed)
    end
  end
  
  describe 'class methods' do
    let(:wallet) { create(:wallet) }
    
    describe '.create_deposit' do
      it 'creates a deposit transaction' do
        transaction = Transaction.create_deposit(
          wallet: wallet,
          amount: 100.0,
          payment_method: :mobile_money,
          provider: 'MTN'
        )
        
        expect(transaction).to be_persisted
        expect(transaction.transaction_type).to eq('deposit')
        expect(transaction.status).to eq('pending')
        expect(transaction.amount).to eq(100.0)
        expect(transaction.destination_wallet).to eq(wallet)
        expect(transaction.payment_method).to eq('mobile_money')
        expect(transaction.provider).to eq('MTN')
      end
    end
    
    describe '.create_withdrawal' do
      it 'creates a withdrawal transaction' do
        transaction = Transaction.create_withdrawal(
          wallet: wallet,
          amount: 50.0,
          payment_method: :mobile_money,
          provider: 'MTN'
        )
        
        expect(transaction).to be_persisted
        expect(transaction.transaction_type).to eq('withdrawal')
        expect(transaction.status).to eq('pending')
        expect(transaction.amount).to eq(50.0)
        expect(transaction.source_wallet).to eq(wallet)
        expect(transaction.payment_method).to eq('mobile_money')
        expect(transaction.provider).to eq('MTN')
      end
    end
    
    describe '.create_transfer' do
      it 'creates a transfer transaction' do
        source_wallet = create(:wallet)
        destination_wallet = create(:wallet)
        
        transaction = Transaction.create_transfer(
          source_wallet: source_wallet,
          destination_wallet: destination_wallet,
          amount: 75.0,
          description: 'Test transfer'
        )
        
        expect(transaction).to be_persisted
        expect(transaction.transaction_type).to eq('transfer')
        expect(transaction.status).to eq('pending')
        expect(transaction.amount).to eq(75.0)
        expect(transaction.source_wallet).to eq(source_wallet)
        expect(transaction.destination_wallet).to eq(destination_wallet)
        expect(transaction.payment_method).to eq('wallet')
        expect(transaction.description).to eq('Test transfer')
      end
    end
    
    describe '.create_payment' do
      it 'creates a payment transaction' do
        source_wallet = create(:wallet)
        destination_wallet = create(:wallet)
        
        transaction = Transaction.create_payment(
          source_wallet: source_wallet,
          destination_wallet: destination_wallet,
          amount: 25.0,
          description: 'Test payment'
        )
        
        expect(transaction).to be_persisted
        expect(transaction.transaction_type).to eq('payment')
        expect(transaction.status).to eq('pending')
        expect(transaction.amount).to eq(25.0)
        expect(transaction.source_wallet).to eq(source_wallet)
        expect(transaction.destination_wallet).to eq(destination_wallet)
        expect(transaction.payment_method).to eq('wallet')
        expect(transaction.description).to eq('Test payment')
      end
    end
  end
  
  describe 'instance methods' do
    describe '#security_check' do
      let(:user) { create(:user) }
      let(:transaction) { create(:transaction, :deposit) }
      
      it 'returns true when security checks pass' do
        # Mock the TransactionSecurityService to always return true
        security_service = instance_double(TransactionSecurityService, secure?: true, errors: [], log_security_check: {risk_score: 0})
        allow(TransactionSecurityService).to receive(:new).and_return(security_service)
        
        expect(transaction.security_check(user)).to be true
      end
      
      it 'returns false and updates transaction status when security checks fail' do
        # Mock the TransactionSecurityService to return false
        security_service = instance_double(TransactionSecurityService, secure?: false, errors: ['Security check failed'], log_security_check: {risk_score: 80})
        allow(TransactionSecurityService).to receive(:new).and_return(security_service)
        
        expect(transaction.security_check(user)).to be false
        expect(transaction.reload.status).to eq('blocked')
        expect(transaction.metadata['security_check']).to be_present
      end
    end
    
    describe '#complete!' do
      context 'with a deposit transaction' do
        let(:wallet) { create(:wallet, balance: 100) }
        let(:transaction) { create(:transaction, transaction_type: :deposit, destination_wallet: wallet, amount: 50) }
        
        it 'credits the destination wallet and updates transaction status' do
          expect(wallet).to receive(:credit).with(50, transaction_id: transaction.transaction_id).and_return(true)
          
          result = transaction.complete!
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('completed')
          expect(transaction.completed_at).not_to be_nil
        end
        
        it 'marks the transaction as failed if wallet operation fails' do
          expect(wallet).to receive(:credit).with(50, transaction_id: transaction.transaction_id).and_return(false)
          
          result = transaction.complete!
          
          expect(result).to be false
          expect(transaction.reload.status).to eq('failed')
          expect(transaction.failed_at).not_to be_nil
        end
      end
      
      context 'with a withdrawal transaction' do
        let(:wallet) { create(:wallet, balance: 100) }
        let(:transaction) { create(:transaction, transaction_type: :withdrawal, source_wallet: wallet, amount: 50) }
        
        it 'debits the source wallet and updates transaction status' do
          expect(wallet).to receive(:debit).with(50, transaction_id: transaction.transaction_id).and_return(true)
          
          result = transaction.complete!
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('completed')
          expect(transaction.completed_at).not_to be_nil
        end
      end
      
      context 'with a transfer transaction' do
        let(:source_wallet) { create(:wallet, balance: 100) }
        let(:destination_wallet) { create(:wallet, balance: 50) }
        let(:transaction) do
          create(:transaction, transaction_type: :transfer, 
                source_wallet: source_wallet, destination_wallet: destination_wallet, amount: 30)
        end
        
        it 'debits the source wallet, credits the destination wallet, and updates transaction status' do
          expect(source_wallet).to receive(:debit).with(30, transaction_id: transaction.transaction_id).and_return(true)
          expect(destination_wallet).to receive(:credit).with(30, transaction_id: transaction.transaction_id).and_return(true)
          
          result = transaction.complete!
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('completed')
          expect(transaction.completed_at).not_to be_nil
        end
        
        it 'marks the transaction as failed if either wallet operation fails' do
          expect(source_wallet).to receive(:debit).with(30, transaction_id: transaction.transaction_id).and_return(true)
          expect(destination_wallet).to receive(:credit).with(30, transaction_id: transaction.transaction_id).and_return(false)
          
          result = transaction.complete!
          
          expect(result).to be false
          expect(transaction.reload.status).to eq('failed')
          expect(transaction.failed_at).not_to be_nil
        end
      end
    end
    
    describe '#fail!' do
      let(:transaction) { create(:transaction, :deposit) }
      
      it 'updates the transaction status to failed' do
        result = transaction.fail!(reason: 'Test failure')
        
        expect(result).to be true
        expect(transaction.reload.status).to eq('failed')
        expect(transaction.failed_at).not_to be_nil
        expect(transaction.metadata['failure_reason']).to eq('Test failure')
      end
      
      it 'returns false if transaction is not in pending state' do
        completed_transaction = create(:transaction, :deposit, :completed)
        
        result = completed_transaction.fail!(reason: 'Test failure')
        
        expect(result).to be false
        expect(completed_transaction.reload.status).to eq('completed')
      end
    end
    
    describe '#reverse!' do
      context 'with a deposit transaction' do
        let(:wallet) { create(:wallet, balance: 150) }
        let(:transaction) { create(:transaction, :deposit, :completed, destination_wallet: wallet, amount: 50) }
        
        it 'debits the destination wallet and updates transaction status' do
          expect(wallet).to receive(:debit).with(50, transaction_id: "REV-#{transaction.transaction_id}").and_return(true)
          
          result = transaction.reverse!(reason: 'Test reversal')
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('reversed')
          expect(transaction.reversed_at).not_to be_nil
          expect(transaction.metadata['reversal_reason']).to eq('Test reversal')
        end
      end
      
      context 'with a withdrawal transaction' do
        let(:wallet) { create(:wallet, balance: 50) }
        let(:transaction) { create(:transaction, :withdrawal, :completed, source_wallet: wallet, amount: 50) }
        
        it 'credits the source wallet and updates transaction status' do
          expect(wallet).to receive(:credit).with(50, transaction_id: "REV-#{transaction.transaction_id}").and_return(true)
          
          result = transaction.reverse!(reason: 'Test reversal')
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('reversed')
          expect(transaction.reversed_at).not_to be_nil
        end
      end
      
      context 'with a transfer transaction' do
        let(:source_wallet) { create(:wallet, balance: 70) }
        let(:destination_wallet) { create(:wallet, balance: 80) }
        let(:transaction) do
          create(:transaction, :transfer, :completed, 
                source_wallet: source_wallet, destination_wallet: destination_wallet, amount: 30)
        end
        
        it 'credits the source wallet, debits the destination wallet, and updates transaction status' do
          expect(source_wallet).to receive(:credit).with(30, transaction_id: "REV-#{transaction.transaction_id}").and_return(true)
          expect(destination_wallet).to receive(:debit).with(30, transaction_id: "REV-#{transaction.transaction_id}").and_return(true)
          
          result = transaction.reverse!(reason: 'Test reversal')
          
          expect(result).to be true
          expect(transaction.reload.status).to eq('reversed')
          expect(transaction.reversed_at).not_to be_nil
        end
      end
      
      it 'returns false if transaction is not in completed state' do
        pending_transaction = create(:transaction, :deposit)
        
        result = pending_transaction.reverse!(reason: 'Test reversal')
        
        expect(result).to be false
        expect(pending_transaction.reload.status).to eq('pending')
      end
    end
    
    describe 'helper methods' do
      let(:user) { create(:user) }
      let(:source_wallet) { create(:wallet, user: user) }
      let(:destination_user) { create(:user) }
      let(:destination_wallet) { create(:wallet, user: destination_user) }
      let(:transaction) do
        create(:transaction, transaction_type: :transfer, 
              source_wallet: source_wallet, destination_wallet: destination_wallet, 
              amount: 100, currency: 'GHS')
      end
      
      describe '#reference' do
        it 'returns a formatted transaction reference' do
          expect(transaction.reference).to match(/TXN-[A-Z0-9]{8}/)
        end
      end
      
      describe '#transaction_type_description' do
        it 'returns a human-readable transaction type' do
          expect(transaction.transaction_type_description).to eq('Wallet Transfer')
          
          deposit = create(:transaction, :deposit)
          expect(deposit.transaction_type_description).to eq('Deposit to Wallet')
          
          withdrawal = create(:transaction, :withdrawal)
          expect(withdrawal.transaction_type_description).to eq('Withdrawal from Wallet')
          
          payment = create(:transaction, :payment)
          expect(payment.transaction_type_description).to eq('Payment')
        end
      end
      
      describe '#recipient_name and #source_name' do
        it 'returns the name of the recipient or source' do
          expect(transaction.recipient_name).to eq(destination_user.display_name)
          expect(transaction.source_name).to eq(user.display_name)
        end
      end
      
      describe '#other_party_name' do
        it 'returns the name of the other party in the transaction' do
          expect(transaction.other_party_name(user.id)).to eq(destination_user.display_name)
          expect(transaction.other_party_name(destination_user.id)).to eq(user.display_name)
        end
      end
      
      describe '#direction_for_user' do
        it 'determines the direction of money flow for a user' do
          expect(transaction.direction_for_user(user.id)).to eq(:outgoing)
          expect(transaction.direction_for_user(destination_user.id)).to eq(:incoming)
        end
      end
      
      describe '#signed_amount_for_user' do
        it 'returns the amount with appropriate sign based on direction' do
          expect(transaction.signed_amount_for_user(user.id)).to include('-')
          expect(transaction.signed_amount_for_user(destination_user.id)).to include('+')
        end
      end
      
      describe '#formatted_amount' do
        it 'formats the amount with currency symbol' do
          expect(transaction.formatted_amount).to eq('₵100.0')
          
          usd_transaction = create(:transaction, :deposit, currency: 'USD', amount: 50)
          expect(usd_transaction.formatted_amount).to eq('$50.0')
        end
      end
    end
  end
end

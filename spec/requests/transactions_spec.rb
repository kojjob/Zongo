require 'rails_helper'

RSpec.describe "Transactions", type: :request do
  let(:user) { create(:user, :with_wallet) }
  let(:wallet) { user.wallet }

  before do
    sign_in user

    # Mock the wallet methods to avoid database operations
    allow_any_instance_of(Wallet).to receive(:credit).and_return(true)
    allow_any_instance_of(Wallet).to receive(:debit).and_return(true)
    allow_any_instance_of(Wallet).to receive(:can_debit?).and_return(true)
  end

  describe "GET /transactions" do
    it "displays the transactions index page" do
      get transactions_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Transactions")
    end

    it "shows the user's transactions" do
      transaction = create(:transaction, :deposit, :completed, destination_wallet: wallet, amount: 100)

      get transactions_path
      expect(response.body).to include(transaction.reference)
      expect(response.body).to include("₵100.0")
    end
  end

  describe "GET /transactions/:id" do
    let(:transaction) { create(:transaction, :deposit, :completed, destination_wallet: wallet, amount: 100) }

    it "displays the transaction details" do
      get transaction_path(transaction)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Transaction Details")
      expect(response.body).to include(transaction.transaction_id)
      expect(response.body).to include("₵100.0")
    end

    it "shows appropriate actions based on transaction status" do
      # Completed transaction should show reverse button
      get transaction_path(transaction)
      expect(response.body).to include("Reverse Transaction")

      # Pending transaction should show process button
      pending_transaction = create(:transaction, :deposit, destination_wallet: wallet)
      get transaction_path(pending_transaction)
      expect(response.body).to include("Process Transaction")
    end

    it "redirects to wallet path if user is not authorized" do
      other_user = create(:user, :with_wallet)
      other_transaction = create(:transaction, :deposit, destination_wallet: other_user.wallet)

      get transaction_path(other_transaction)
      expect(response).to redirect_to(wallet_path)
    end
  end

  describe "GET /transactions/new" do
    it "displays the new transaction form" do
      get new_transaction_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Transfer Transaction")
    end

    it "shows different forms based on transaction type" do
      get new_transaction_path(type: 'deposit')
      expect(response.body).to include("Deposit Money")

      get new_transaction_path(type: 'withdrawal')
      expect(response.body).to include("Withdraw Money")

      get new_transaction_path(type: 'transfer')
      expect(response.body).to include("Transfer Money")

      get new_transaction_path(type: 'payment')
      expect(response.body).to include("Make a Payment")
    end
  end

  describe "POST /transactions" do
    context "with deposit transaction" do
      let(:valid_params) do
        {
          transaction: {
            transaction_type: 'deposit',
            amount: '100',
            payment_method: 'mobile_money',
            provider: 'MTN'
          }
        }
      end

      it "creates a new deposit transaction and redirects to the transaction page" do
        # Mock the security check and transaction service to avoid external dependencies
        allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)
        allow_any_instance_of(TransactionService).to receive(:process).and_return({ success: true })

        # Mock the payment processor to avoid external dependencies
        mock_processor = double("PaymentProcessor")
        allow(mock_processor).to receive(:verify_deposit).and_return({ success: true })
        allow_any_instance_of(TransactionService).to receive(:payment_processor_for).and_return(mock_processor)

        expect {
          post transactions_path, params: valid_params
        }.to change(Transaction, :count).by(1)

        expect(response).to redirect_to(transaction_path(Transaction.last))
        expect(flash[:notice]).to match(/created successfully/)
      end
    end

    context "with withdrawal transaction" do
      let(:valid_params) do
        {
          transaction: {
            transaction_type: 'withdrawal',
            amount: '50',
            payment_method: 'mobile_money',
            provider: 'MTN',
            destination: {
              phone_number: '0123456789'
            }
          }
        }
      end

      it "creates a new withdrawal transaction and redirects to the transaction page" do
        # Mock the security check and transaction service to avoid external dependencies
        allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)
        allow_any_instance_of(TransactionService).to receive(:process).and_return({ success: true })

        # Mock the wallet to allow debits
        allow_any_instance_of(Wallet).to receive(:can_debit?).and_return(true)

        # Mock the payment processor to avoid external dependencies
        mock_processor = double("PaymentProcessor")
        allow(mock_processor).to receive(:process_withdrawal).and_return({ success: true, provider_reference: "REF123" })
        allow_any_instance_of(TransactionService).to receive(:payment_processor_for).and_return(mock_processor)

        expect {
          post transactions_path, params: valid_params
        }.to change(Transaction, :count).by(1)

        expect(response).to redirect_to(transaction_path(Transaction.last))
        expect(flash[:notice]).to match(/created successfully/)
      end
    end

    context "with transfer transaction" do
      let(:destination_wallet) { create(:wallet) }
      let(:valid_params) do
        {
          transaction: {
            transaction_type: 'transfer',
            amount: '75',
            destination_wallet_id: destination_wallet.id,
            description: 'Test transfer'
          }
        }
      end

      it "creates a new transfer transaction and redirects to the transaction page" do
        # Mock the security check and transaction service to avoid external dependencies
        allow_any_instance_of(Transaction).to receive(:security_check).and_return(true)
        allow_any_instance_of(TransactionService).to receive(:process).and_return({ success: true })

        # Mock the wallet to allow debits
        allow_any_instance_of(Wallet).to receive(:can_debit?).and_return(true)

        # Mock the complete method to avoid wallet operations
        allow_any_instance_of(Transaction).to receive(:complete!).and_return(true)

        expect {
          post transactions_path, params: valid_params
        }.to change(Transaction, :count).by(1)

        expect(response).to redirect_to(transaction_path(Transaction.last))
        expect(flash[:notice]).to match(/created successfully/)
      end
    end
  end

  describe "POST /transactions/:id/process_transaction" do
    let(:transaction) { create(:transaction, :deposit, destination_wallet: wallet) }

    it "processes a pending transaction and redirects to the transaction page" do
      # Mock the transaction service to avoid external dependencies
      allow_any_instance_of(TransactionService).to receive(:process).and_return({ success: true })

      post process_transaction_transaction_path(transaction)

      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:notice]).to match(/processed successfully/)
    end

    it "redirects with an alert if transaction cannot be processed" do
      completed_transaction = create(:transaction, :deposit, :completed, destination_wallet: wallet)

      post process_transaction_transaction_path(completed_transaction)

      expect(response).to redirect_to(transaction_path(completed_transaction))
      expect(flash[:alert]).to match(/cannot be processed/)
    end
  end

  describe "POST /transactions/:id/reverse" do
    let(:completed_transaction) { create(:transaction, :deposit, :completed, destination_wallet: wallet) }

    it "reverses a completed transaction and redirects to the transaction page" do
      # Mock the reverse method to avoid wallet operations
      allow_any_instance_of(Transaction).to receive(:reverse!).and_return(true)

      post reverse_transaction_path(completed_transaction)

      expect(response).to redirect_to(transaction_path(completed_transaction))
      expect(flash[:notice]).to match(/reversed successfully/)
    end

    it "redirects with an alert if transaction cannot be reversed" do
      pending_transaction = create(:transaction, :deposit, destination_wallet: wallet)

      post reverse_transaction_path(pending_transaction)

      expect(response).to redirect_to(transaction_path(pending_transaction))
      expect(flash[:alert]).to match(/cannot be reversed/)
    end
  end
end

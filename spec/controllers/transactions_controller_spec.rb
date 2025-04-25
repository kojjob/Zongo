require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  let(:user) { create(:user, :with_wallet) }
  let(:wallet) { user.wallet }
  
  before do
    sign_in user
  end
  
  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end
    
    it 'assigns @transactions' do
      transaction = create(:transaction, :deposit, destination_wallet: wallet)
      get :index
      expect(assigns(:transactions)).to include(transaction)
    end
    
    it 'paginates the transactions' do
      allow(controller).to receive(:pagy)
      get :index
      expect(controller).to have_received(:pagy)
    end
  end
  
  describe 'GET #show' do
    let(:transaction) { create(:transaction, :deposit, destination_wallet: wallet) }
    
    it 'returns a success response' do
      get :show, params: { id: transaction.id }
      expect(response).to be_successful
    end
    
    it 'assigns the requested transaction as @transaction' do
      get :show, params: { id: transaction.id }
      expect(assigns(:transaction)).to eq(transaction)
    end
    
    it 'redirects if user is not authorized to view the transaction' do
      other_user = create(:user, :with_wallet)
      other_transaction = create(:transaction, :deposit, destination_wallet: other_user.wallet)
      
      get :show, params: { id: other_transaction.id }
      expect(response).to redirect_to(wallet_path)
      expect(flash[:alert]).to match(/not authorized/)
    end
  end
  
  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end
    
    it 'assigns a new transaction as @transaction' do
      get :new
      expect(assigns(:transaction)).to be_a_new(Transaction)
    end
    
    it 'sets the transaction type based on params' do
      get :new, params: { type: 'deposit' }
      expect(assigns(:transaction_type)).to eq('deposit')
    end
    
    it 'defaults to transfer if no type is provided' do
      get :new
      expect(assigns(:transaction_type)).to eq('transfer')
    end
  end
  
  describe 'POST #create' do
    context 'with deposit transaction' do
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
      
      it 'creates a new deposit transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
        
        expect(Transaction.last.transaction_type).to eq('deposit')
        expect(Transaction.last.destination_wallet).to eq(wallet)
      end
      
      it 'performs a security check on the transaction' do
        transaction = build(:transaction)
        allow(Transaction).to receive(:create_deposit).and_return(transaction)
        expect(transaction).to receive(:security_check).with(user, anything, anything).and_return(true)
        
        post :create, params: valid_params
      end
      
      it 'processes the transaction if security check passes' do
        transaction = build(:transaction)
        allow(Transaction).to receive(:create_deposit).and_return(transaction)
        allow(transaction).to receive(:security_check).and_return(true)
        allow(transaction).to receive(:persisted?).and_return(true)
        
        expect(controller).to receive(:process_transaction_with_service).with(transaction).and_return({ success: true })
        
        post :create, params: valid_params
      end
      
      it 'redirects to the transaction page with success notice if processing succeeds' do
        transaction = create(:transaction)
        allow(Transaction).to receive(:create_deposit).and_return(transaction)
        allow(transaction).to receive(:security_check).and_return(true)
        allow(controller).to receive(:process_transaction_with_service).and_return({ success: true })
        
        post :create, params: valid_params
        
        expect(response).to redirect_to(transaction_path(transaction))
        expect(flash[:notice]).to match(/created successfully/)
      end
      
      it 'redirects to the transaction page with alert if security check fails' do
        transaction = create(:transaction)
        allow(Transaction).to receive(:create_deposit).and_return(transaction)
        allow(transaction).to receive(:security_check).and_return(false)
        allow(transaction).to receive(:persisted?).and_return(true)
        
        post :create, params: valid_params
        
        expect(response).to redirect_to(transaction_path(transaction))
        expect(flash[:alert]).to match(/blocked by security checks/)
      end
    end
    
    context 'with withdrawal transaction' do
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
      
      it 'creates a new withdrawal transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
        
        expect(Transaction.last.transaction_type).to eq('withdrawal')
        expect(Transaction.last.source_wallet).to eq(wallet)
      end
    end
    
    context 'with transfer transaction' do
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
      
      it 'creates a new transfer transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
        
        expect(Transaction.last.transaction_type).to eq('transfer')
        expect(Transaction.last.source_wallet).to eq(wallet)
        expect(Transaction.last.destination_wallet).to eq(destination_wallet)
      end
    end
    
    context 'with payment transaction' do
      let(:merchant_wallet) { create(:wallet) }
      let(:valid_params) do
        {
          transaction: {
            transaction_type: 'payment',
            amount: '25',
            destination_wallet_id: merchant_wallet.id,
            description: 'Test payment',
            destination: {
              reference: 'INV123'
            }
          }
        }
      end
      
      it 'creates a new payment transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
        
        expect(Transaction.last.transaction_type).to eq('payment')
        expect(Transaction.last.source_wallet).to eq(wallet)
        expect(Transaction.last.destination_wallet).to eq(merchant_wallet)
      end
    end
    
    context 'with invalid transaction type' do
      let(:invalid_params) do
        {
          transaction: {
            transaction_type: 'invalid_type',
            amount: '100'
          }
        }
      end
      
      it 'redirects to wallet path with an alert' do
        post :create, params: invalid_params
        
        expect(response).to redirect_to(wallet_path)
        expect(flash[:alert]).to match(/Invalid transaction type/)
      end
    end
  end
  
  describe 'POST #process_transaction' do
    let(:transaction) { create(:transaction, :deposit, destination_wallet: wallet) }
    
    it 'processes a pending transaction' do
      expect(controller).to receive(:process_transaction_with_service).with(transaction).and_return({ success: true })
      
      post :process_transaction, params: { id: transaction.id }
      
      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:notice]).to match(/processed successfully/)
    end
    
    it 'redirects with an alert if transaction cannot be processed' do
      completed_transaction = create(:transaction, :deposit, :completed, destination_wallet: wallet)
      
      post :process_transaction, params: { id: completed_transaction.id }
      
      expect(response).to redirect_to(transaction_path(completed_transaction))
      expect(flash[:alert]).to match(/cannot be processed/)
    end
    
    it 'redirects with an alert if processing fails' do
      expect(controller).to receive(:process_transaction_with_service).with(transaction).and_return({ success: false, message: 'Processing failed' })
      
      post :process_transaction, params: { id: transaction.id }
      
      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:alert]).to match(/Processing failed/)
    end
  end
  
  describe 'POST #reverse' do
    let(:completed_transaction) { create(:transaction, :deposit, :completed, destination_wallet: wallet) }
    
    it 'reverses a completed transaction' do
      expect(completed_transaction).to receive(:reverse!).with(reason: nil).and_return(true)
      
      post :reverse, params: { id: completed_transaction.id }
      
      expect(response).to redirect_to(transaction_path(completed_transaction))
      expect(flash[:notice]).to match(/reversed successfully/)
    end
    
    it 'accepts a reason for the reversal' do
      expect(completed_transaction).to receive(:reverse!).with(reason: 'Test reason').and_return(true)
      
      post :reverse, params: { id: completed_transaction.id, reason: 'Test reason' }
      
      expect(response).to redirect_to(transaction_path(completed_transaction))
    end
    
    it 'redirects with an alert if transaction cannot be reversed' do
      pending_transaction = create(:transaction, :deposit, destination_wallet: wallet)
      
      post :reverse, params: { id: pending_transaction.id }
      
      expect(response).to redirect_to(transaction_path(pending_transaction))
      expect(flash[:alert]).to match(/cannot be reversed/)
    end
    
    it 'redirects with an alert if reversal fails' do
      expect(completed_transaction).to receive(:reverse!).with(reason: nil).and_return(false)
      
      post :reverse, params: { id: completed_transaction.id }
      
      expect(response).to redirect_to(transaction_path(completed_transaction))
      expect(flash[:alert]).to match(/Failed to reverse/)
    end
  end
  
  describe '#process_transaction_with_service' do
    let(:transaction) { create(:transaction, :deposit, destination_wallet: wallet) }
    
    it 'creates a transaction service and processes the transaction' do
      service = instance_double(TransactionService)
      expect(TransactionService).to receive(:new).with(transaction, user, anything, anything).and_return(service)
      expect(service).to receive(:process).with(external_reference: nil, verification_data: {}).and_return({ success: true })
      
      result = controller.send(:process_transaction_with_service, transaction)
      
      expect(result[:success]).to be true
    end
    
    it 'passes external reference and verification data to the service' do
      service = instance_double(TransactionService)
      expect(TransactionService).to receive(:new).and_return(service)
      expect(service).to receive(:process).with(
        external_reference: 'EXT123',
        verification_data: { 'pin' => '1234' }
      ).and_return({ success: true })
      
      controller.params[:external_reference] = 'EXT123'
      controller.params[:verification_data] = { 'pin' => '1234' }
      
      controller.send(:process_transaction_with_service, transaction)
    end
  end
end

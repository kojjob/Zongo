class WalletController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wallet
  before_action :set_qr_code_data, only: [:receive_money]
  
  def dashboard
    @recent_transactions = current_user.transactions.order(created_at: :desc).limit(5)
    @balance = @wallet.balance
    @currency_symbol = @wallet.currency_symbol
  end
  
  def send_money
    @recent_recipients = current_user.beneficiaries.order(last_used_at: :desc).limit(10)
    
    if request.post?
      # Handle the form submission
      recipient_wallet = Wallet.find_by(wallet_id: params[:account_number])
      
      if recipient_wallet.nil?
        flash[:error] = "Recipient account not found"
        return render :send_money
      end
      
      amount = params[:amount].to_f
      
      if amount <= 0
        flash[:error] = "Please enter a valid amount"
        return render :send_money
      end
      
      if amount > @wallet.balance
        flash[:error] = "Insufficient funds"
        return render :send_money
      end
      
      # Process the transaction
      transaction = TransactionService.new(
        sender_wallet: @wallet,
        recipient_wallet: recipient_wallet,
        amount: amount,
        description: params[:description],
        transaction_type: 'transfer'
      ).process
      
      if transaction.persisted?
        # Update beneficiary last used time or create a new one
        beneficiary = current_user.beneficiaries.find_or_initialize_by(
          account_number: recipient_wallet.wallet_id
        )
        
        if beneficiary.new_record?
          beneficiary.name = params[:recipient_name]
          beneficiary.bank_name = "Super Ghana Bank"
        end
        
        beneficiary.last_used_at = Time.current
        beneficiary.save
        
        flash[:success] = "Money sent successfully!"
        redirect_to transaction_path(transaction)
      else
        flash[:error] = "Failed to process transaction"
        render :send_money
      end
    end
  end
  
  def receive_money
    # Set active tab if specified in params
    @active_tab = params[:active_tab] if params[:active_tab].present?
    
    # Generate payment link if not already exists
    if @wallet.payment_link.blank?
      @wallet.update(payment_link: generate_payment_link)
    end
    
    @payment_link = @wallet.payment_link
    
    # Custom amount handling
    if params[:amount].present?
      @custom_amount = params[:amount].to_f
      @custom_purpose = params[:purpose]
      
      # Update QR code data with amount
      @qr_code_data = generate_qr_code_data(amount: @custom_amount, purpose: @custom_purpose)
    end
    
    # Fetch recent payment links for display
    @recent_payment_links = current_user.payment_links.order(created_at: :desc).limit(5)
  end
  
  def bills
    @bill_categories = BillCategory.all
    @recent_bill_payments = current_user.transactions.where(transaction_type: 'bill_payment').order(created_at: :desc).limit(5)
  end
  
  def pay_bill
    @bill_provider = BillProvider.find(params[:provider_id])
    
    if request.post?
      amount = params[:amount].to_f
      account_number = params[:account_number]
      
      if amount <= 0
        flash[:error] = "Please enter a valid amount"
        return render :pay_bill
      end
      
      if amount > @wallet.balance
        flash[:error] = "Insufficient funds"
        return render :pay_bill
      end
      
      # Process the bill payment
      transaction = TransactionService.new(
        sender_wallet: @wallet,
        recipient_wallet: @bill_provider.wallet,
        amount: amount,
        description: "Bill payment - #{@bill_provider.name} - #{account_number}",
        transaction_type: 'bill_payment',
        metadata: {
          bill_provider_id: @bill_provider.id,
          account_number: account_number
        }
      ).process
      
      if transaction.persisted?
        flash[:success] = "Bill payment successful!"
        redirect_to transaction_path(transaction)
      else
        flash[:error] = "Failed to process bill payment"
        render :pay_bill
      end
    end
  end
  
  def transactions
    @transactions = current_user.transactions.order(created_at: :desc).page(params[:page]).per(20)
  end
  
  def payment_page
    # This handles the public payment page when someone clicks a payment link
    @recipient = User.find_by(id: params[:user_id])
    
    if @recipient.nil?
      flash[:error] = "Invalid payment link"
      return redirect_to root_path
    end
    
    @recipient_wallet = @recipient.wallet
    @amount = params[:amount]
    
    if user_signed_in?
      @sender_wallet = current_user.wallet
    end
  end
  
  def new_beneficiary
    @beneficiary = current_user.beneficiaries.new
    
    if request.post?
      @beneficiary = current_user.beneficiaries.new(beneficiary_params)
      
      if @beneficiary.save
        flash[:success] = "Beneficiary added successfully!"
        redirect_to beneficiaries_path
      else
        flash[:error] = "Failed to add beneficiary"
        render :new_beneficiary
      end
    end
  end
  
  def beneficiaries
    @beneficiaries = current_user.beneficiaries.order(name: :asc)
  end
  
  private
  
  def set_wallet
    @wallet = current_user.wallet
  end
  
  def set_qr_code_data
    @qr_code_data = generate_qr_code_data
  end
  
  def generate_qr_code_data(amount: nil, purpose: nil)
    base_url = Rails.application.routes.url_helpers.payment_url(
      user_id: current_user.id,
      host: ENV['APPLICATION_HOST']
    )
    
    url = base_url
    
    # Add amount and purpose if provided
    if amount.present?
      url += "?amount=#{amount}"
      url += "&purpose=#{CGI.escape(purpose)}" if purpose.present?
    end
    
    # Return the URL as the QR code data
    url
  end
  
  def generate_payment_link
    # Generate a unique payment link for the user
    token = SecureRandom.urlsafe_base64(8)
    
    Rails.application.routes.url_helpers.payment_url(
      user_id: current_user.id,
      token: token,
      host: ENV['APPLICATION_HOST']
    )
  end
  
  def beneficiary_params
    params.require(:beneficiary).permit(:name, :account_number, :bank_name)
  end
end
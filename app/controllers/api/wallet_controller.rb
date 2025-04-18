module Api
  class WalletController < ApplicationController
    before_action :authenticate_user!
    before_action :set_wallet
    
    # Endpoint to generate QR code with specific amount
    def generate_qr
      amount = params[:amount].to_f
      purpose = params[:purpose]
      
      if amount <= 0
        return render json: { success: false, error: "Please enter a valid amount" }
      end
      
      # Redirect parameters to receive_money with the right tab and amount
      # The actual QR code generation happens in the receive_money action
      render json: { 
        success: true, 
        redirect_url: wallet_receive_money_path(active_tab: 'qr_code', amount: amount, purpose: purpose) 
      }
    end
    
    # Endpoint to generate custom payment links
    def generate_payment_link
      amount = params[:amount].present? ? params[:amount].to_f : nil
      purpose = params[:purpose]
      expiry = params[:expiry]
      
      # Set expiry date based on selection
      expires_at = case expiry
                   when '24h'
                     24.hours.from_now
                   when '7d'
                     7.days.from_now
                   when '30d'
                     30.days.from_now
                   else
                     nil
                   end
      
      # Create a unique token for this payment link
      token = SecureRandom.urlsafe_base64(12)
      
      # Base URL for payment
      base_url = Rails.application.routes.url_helpers.payment_url(
        user_id: current_user.id,
        token: token,
        host: ENV['APPLICATION_HOST']
      )
      
      # Add amount and purpose parameters if provided
      url = base_url
      url += "?amount=#{amount}" if amount.present?
      url += "&purpose=#{CGI.escape(purpose)}" if purpose.present?
      
      # Create a payment link record
      payment_link = current_user.payment_links.new(
        url: url,
        token: token,
        amount: amount,
        purpose: purpose,
        expires_at: expires_at
      )
      
      if payment_link.save
        render json: { 
          success: true, 
          payment_link: url,
          link_id: payment_link.id,
          redirect_url: wallet_receive_money_path(active_tab: 'payment_link')
        }
      else
        render json: { 
          success: false, 
          error: payment_link.errors.full_messages.join(", ")
        }
      end
    end
    
    # Endpoint to delete a payment link
    def delete_payment_link
      payment_link = current_user.payment_links.find_by(id: params[:id])
      
      if payment_link.nil?
        return render json: { success: false, error: "Payment link not found" }
      end
      
      if payment_link.destroy
        render json: { success: true }
      else
        render json: { 
          success: false, 
          error: payment_link.errors.full_messages.join(", ")
        }
      end
    end
    
    # Endpoint to get transaction history
    def transactions
      page = params[:page] || 1
      per_page = params[:per_page] || 20
      
      transactions = current_user.transactions
      
      # Apply filters if provided
      if params[:type].present?
        transactions = transactions.where(transaction_type: params[:type])
      end
      
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date]).beginning_of_day
        end_date = Date.parse(params[:end_date]).end_of_day
        transactions = transactions.where(created_at: start_date..end_date)
      end
      
      # Paginate results
      transactions = transactions.order(created_at: :desc).page(page).per(per_page)
      
      render json: {
        success: true,
        transactions: transactions.as_json(include: [:sender, :recipient]),
        meta: {
          current_page: transactions.current_page,
          total_pages: transactions.total_pages,
          total_count: transactions.total_count
        }
      }
    end
    
    # Endpoint to check account balance
    def balance
      render json: {
        success: true,
        balance: @wallet.balance,
        currency: @wallet.currency,
        currency_symbol: @wallet.currency_symbol,
        available_balance: @wallet.available_balance,
        pending_balance: @wallet.pending_balance
      }
    end
    
    # Endpoint to validate an account number
    def validate_account
      account_number = params[:account_number]
      
      if account_number.blank?
        return render json: { success: false, error: "Account number is required" }
      end
      
      recipient_wallet = Wallet.find_by(wallet_id: account_number)
      
      if recipient_wallet.nil?
        return render json: { success: false, error: "Account not found" }
      end
      
      # Don't allow sending to self
      if recipient_wallet.id == @wallet.id
        return render json: { success: false, error: "Cannot send money to yourself" }
      end
      
      render json: {
        success: true,
        account_name: recipient_wallet.user.full_name,
        account_number: recipient_wallet.wallet_id
      }
    end
    
    private
    
    def set_wallet
      @wallet = current_user.wallet
    end
  end
end
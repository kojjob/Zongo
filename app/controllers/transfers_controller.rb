class TransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wallet
  before_action :check_account_security, only: [ :create ]
  before_action :verify_pin, only: [ :create ], if: :requires_pin_verification?

  # GET /transfers/new
  def new
    @recent_recipients = current_user.recent_transfer_recipients(5)
    @beneficiaries = current_user.beneficiaries.recent.limit(5)

    # For demo purposes - handle test user creation
    if params[:create_test_user].present?
      email = params[:create_test_user]
      # Check if user already exists
      unless User.exists?(email: email)
        # Create a test user with the provided email
        test_user = User.new(
          email: email,
          password: "password123", # Simple password for demo
          username: email.split("@").first
        )

        if test_user.save
          # Create a wallet for the new user
          wallet = Wallet.create(
            user: test_user,
            balance: 1000, # Give them some initial balance
            currency: "GHS",
            daily_limit: 5000
          )

          flash[:success] = "Test user '#{email}' created successfully! You can now transfer money to them."
        else
          flash[:error] = "Could not create test user: #{test_user.errors.full_messages.join(', ')}"
        end
      else
        flash[:notice] = "User with email '#{email}' already exists. You can transfer money to them."
      end

      # Store the email as the recipient for the form
      flash[:recipient_attempt] = email
    end
  end

  # POST /transfers
  def create
    amount = params[:amount].to_f
    recipient_identifier = params[:recipient]
    description = params[:description]

    # Validate inputs
    if amount <= 0
      flash[:error] = "Amount must be greater than zero"
      redirect_to new_transfer_path
      return
    end

    if amount > @wallet.balance
      flash[:error] = "Insufficient balance for this transfer"
      redirect_to new_transfer_path
      return
    end

    if recipient_identifier.blank?
      flash[:error] = "Please specify a recipient"
      redirect_to new_transfer_path
      return
    end

    # Find recipient wallet
    recipient = User.find_by(phone: recipient_identifier) ||
                User.find_by(email: recipient_identifier) ||
                User.find_by(username: recipient_identifier)

    unless recipient
      # Provide more helpful error message
      if recipient_identifier.include?("@")
        flash[:error] = "No user found with email '#{recipient_identifier}'. Please check the email address or invite this person to join."
      elsif recipient_identifier.match?(/^\d+$/) # Looks like a phone number
        flash[:error] = "No user found with phone number '#{recipient_identifier}'. Please check the number or invite this person to join."
      else
        flash[:error] = "No user found with username '#{recipient_identifier}'. Please check the username or try using their email or phone number instead."
      end

      # Store the attempted recipient for form repopulation
      flash[:recipient_attempt] = recipient_identifier

      redirect_to new_transfer_path
      return
    end

    recipient_wallet = recipient.wallet

    # Prevent transfers to self
    if recipient.id == current_user.id
      flash[:error] = "You cannot transfer money to yourself"
      redirect_to new_transfer_path
      return
    end

    # Check daily limit
    if @wallet.daily_limit_exceeded?(amount)
      flash[:error] = "This transfer would exceed your daily transaction limit"
      redirect_to new_transfer_path
      return
    end

    # Create transfer transaction
    transaction = Transaction.create_transfer(
      source_wallet: @wallet,
      destination_wallet: recipient_wallet,
      amount: amount,
      description: description,
      metadata: {
        sender_name: current_user.display_name,
        recipient_name: recipient.display_name,
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        verification_provided: params[:verification_code].present?
      }
    )

    if transaction.persisted?
      # Run security checks
      security_passed = transaction.security_check(current_user, request.remote_ip, request.user_agent)

      unless security_passed
        flash[:error] = "Transaction blocked due to security concerns. Please contact support."
        redirect_to wallet_path
        return
      end

      # Process the transfer
      if transaction.complete!
        flash[:success] = "Successfully transferred #{transaction.formatted_amount} to #{recipient.display_name}"
      else
        flash[:warning] = "Your transfer is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to new_transfer_path
    end
  end

  private

  def set_wallet
    @wallet = current_user.wallet
  end

  def check_account_security
    # Implement security checks as needed
    true
  end

  def verify_pin
    # Implement PIN verification as needed
    true
  end

  def requires_pin_verification?
    # Determine if PIN verification is required
    amount = params[:amount].to_f
    amount >= 500 # Example threshold
  end
end

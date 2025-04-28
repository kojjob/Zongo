module Transportation
  class PaymentService
    attr_reader :user, :amount, :payment_method, :description, :booking

    def initialize(user:, amount:, payment_method:, description:, booking:)
      @user = user
      @amount = amount
      @payment_method = payment_method
      @description = description
      @booking = booking
    end

    def process_payment
      # Create a transaction record
      transaction = Transaction.new(
        user: user,
        amount: amount,
        transaction_type: 'payment',
        status: 'pending',
        description: description,
        payment_method: payment_method,
        metadata: {
          booking_type: booking.class.name,
          booking_id: booking.id
        }
      )

      # Process the payment based on the payment method
      case payment_method
      when 'wallet'
        process_wallet_payment(transaction)
      when 'card', 'mobile_money', 'bank_transfer'
        process_external_payment(transaction)
      else
        transaction.status = 'failed'
        transaction.notes = "Invalid payment method: #{payment_method}"
        transaction.save
        return { success: false, message: "Invalid payment method", transaction: transaction }
      end
    end

    private

    def process_wallet_payment(transaction)
      # Check if user has enough balance
      wallet = user.wallet
      
      if wallet.nil?
        transaction.status = 'failed'
        transaction.notes = "User does not have a wallet"
        transaction.save
        return { success: false, message: "You don't have a wallet", transaction: transaction }
      end

      if wallet.balance < amount
        transaction.status = 'failed'
        transaction.notes = "Insufficient funds"
        transaction.save
        return { success: false, message: "Insufficient funds in your wallet", transaction: transaction }
      end

      # Deduct from wallet
      wallet.balance -= amount
      
      if wallet.save
        # Update transaction status
        transaction.status = 'completed'
        transaction.save
        
        # Update booking status
        update_booking_status(transaction)
        
        # Return success
        { success: true, message: "Payment successful", transaction: transaction }
      else
        transaction.status = 'failed'
        transaction.notes = "Failed to update wallet balance"
        transaction.save
        { success: false, message: "Failed to process payment", transaction: transaction }
      end
    end

    def process_external_payment(transaction)
      # In a real implementation, this would integrate with a payment gateway
      # For now, we'll just simulate a successful payment
      
      # Update transaction status
      transaction.status = 'completed'
      transaction.save
      
      # Update booking status
      update_booking_status(transaction)
      
      # Return success
      { success: true, message: "Payment successful", transaction: transaction }
    end

    def update_booking_status(transaction)
      if transaction.status == 'completed'
        case booking
        when RideBooking
          booking.update(status: :confirmed)
        when TicketBooking
          booking.update(status: :confirmed)
        end
      end
    end
  end
end

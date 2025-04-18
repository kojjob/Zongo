module TransactionsHelper
  # Get the CSS class for a transaction type badge
  def transaction_type_badge_class(type)
    case type
    when "deposit"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
    when "withdrawal"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
    when "transfer"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    when "payment"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300"
    else
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"
    end
  end

  # Get the CSS class for a transaction status badge
  def transaction_status_badge_class(status)
    case status
    when "pending"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
    when "completed"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
    when "failed"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
    when "reversed"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"
    when "blocked"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
    else
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"
    end
  end

  # Get the CSS class for a transaction amount
  def transaction_amount_class(transaction, user_id)
    direction = transaction.direction_for_user(user_id)
    case direction
    when :incoming
      "text-green-600 dark:text-green-400"
    when :outgoing
      "text-red-600 dark:text-red-400"
    else
      "text-gray-900 dark:text-white"
    end
  end

  # Get the CSS class for a transaction status header
  def transaction_status_header_class(status)
    case status
    when "pending"
      "bg-gradient-to-r from-yellow-500 to-yellow-600"
    when "completed"
      "bg-gradient-to-r from-green-500 to-green-600"
    when "failed"
      "bg-gradient-to-r from-red-500 to-red-600"
    when "reversed"
      "bg-gradient-to-r from-gray-500 to-gray-600"
    when "blocked"
      "bg-gradient-to-r from-red-500 to-red-600"
    else
      "bg-gradient-to-r from-gray-500 to-gray-600"
    end
  end

  # Get the CSS class for a transaction status icon
  def transaction_status_icon_class(status)
    base_class = "w-12 h-12 rounded-full flex items-center justify-center"
    case status
    when "pending"
      "#{base_class} bg-yellow-100 text-yellow-600"
    when "completed"
      "#{base_class} bg-green-100 text-green-600"
    when "failed"
      "#{base_class} bg-red-100 text-red-600"
    when "reversed"
      "#{base_class} bg-gray-100 text-gray-600"
    when "blocked"
      "#{base_class} bg-red-100 text-red-600"
    else
      "#{base_class} bg-gray-100 text-gray-600"
    end
  end

  # Get the icon for a transaction status
  def transaction_status_icon(status)
    case status
    when "pending"
      icon("clock", class: "w-6 h-6")
    when "completed"
      icon("check", class: "w-6 h-6")
    when "failed"
      icon("x-mark", class: "w-6 h-6")
    when "reversed"
      icon("arrow-path", class: "w-6 h-6")
    when "blocked"
      icon("shield-exclamation", class: "w-6 h-6")
    else
      icon("question-mark-circle", class: "w-6 h-6")
    end
  end

  # Get a message describing the transaction status
  def transaction_status_message(transaction)
    case transaction.status
    when "pending"
      "This transaction is waiting to be processed."
    when "completed"
      "This transaction has been successfully completed."
    when "failed"
      if transaction.metadata && transaction.metadata["failure_reason"].present?
        "This transaction failed: #{transaction.metadata["failure_reason"]}"
      else
        "This transaction failed to process."
      end
    when "reversed"
      if transaction.metadata && transaction.metadata["reversal_reason"].present?
        "This transaction was reversed: #{transaction.metadata["reversal_reason"]}"
      else
        "This transaction was reversed."
      end
    when "blocked"
      if transaction.metadata && transaction.metadata.dig("security_check", "reasons").present?
        if transaction.metadata.dig("security_check", "reasons").is_a?(Array)
          "This transaction was blocked: #{transaction.metadata.dig("security_check", "reasons").join(", ")}"
        else
          "This transaction was blocked: #{transaction.metadata.dig("security_check", "reasons")}"
        end
      else
        "This transaction was blocked by security checks."
      end
    else
      "Unknown transaction status."
    end
  end

  # Get the CSS class for a transaction type header
  def transaction_type_header_class(type)
    case type
    when "deposit"
      "bg-gradient-to-r from-green-500 to-green-600"
    when "withdrawal"
      "bg-gradient-to-r from-red-500 to-red-600"
    when "transfer"
      "bg-gradient-to-r from-blue-500 to-blue-600"
    when "payment"
      "bg-gradient-to-r from-purple-500 to-purple-600"
    else
      "bg-gradient-to-r from-gray-500 to-gray-600"
    end
  end

  # Get the CSS class for a transaction type icon
  def transaction_type_icon_class(type)
    base_class = "w-12 h-12 rounded-full flex items-center justify-center"
    case type
    when "deposit"
      "#{base_class} bg-green-100 text-green-600"
    when "withdrawal"
      "#{base_class} bg-red-100 text-red-600"
    when "transfer"
      "#{base_class} bg-blue-100 text-blue-600"
    when "payment"
      "#{base_class} bg-purple-100 text-purple-600"
    else
      "#{base_class} bg-gray-100 text-gray-600"
    end
  end

  # Get the icon for a transaction type
  def transaction_type_icon(type)
    case type
    when "deposit"
      icon("arrow-down-to-line", class: "w-6 h-6")
    when "withdrawal"
      icon("arrow-up-from-line", class: "w-6 h-6")
    when "transfer"
      icon("arrow-right-arrow-left", class: "w-6 h-6")
    when "payment"
      icon("credit-card", class: "w-6 h-6")
    else
      icon("question-mark-circle", class: "w-6 h-6")
    end
  end

  # Get the title for a transaction type
  def transaction_type_title(type)
    case type
    when "deposit"
      "Deposit Money"
    when "withdrawal"
      "Withdraw Money"
    when "transfer"
      "Transfer Money"
    when "payment"
      "Make a Payment"
    else
      "New Transaction"
    end
  end

  # Get the description for a transaction type
  def transaction_type_description(type)
    case type
    when "deposit"
      "Add money to your wallet from an external source."
    when "withdrawal"
      "Withdraw money from your wallet to an external destination."
    when "transfer"
      "Send money to another user's wallet."
    when "payment"
      "Pay for goods or services."
    else
      "Create a new transaction."
    end
  end

  # Get payment method options for select
  def payment_method_options
    [
      [ "Mobile Money", "mobile_money" ],
      [ "Bank Transfer", "bank_transfer" ],
      [ "Card Payment", "card_payment" ],
      [ "Cash", "cash" ]
    ]
  end

  # Get provider options for select based on transaction type
  def provider_options_for(transaction_type)
    case transaction_type
    when "deposit", "withdrawal"
      [
        [ "MTN Mobile Money", "MTN" ],
        [ "Vodafone Cash", "Vodafone" ],
        [ "AirtelTigo Money", "AirtelTigo" ],
        [ "Ghana Commercial Bank", "GCB" ],
        [ "Ecobank", "Ecobank" ],
        [ "Fidelity Bank", "Fidelity" ],
        [ "Visa", "Visa" ],
        [ "Mastercard", "Mastercard" ]
      ]
    else
      [
        [ "Select Provider", "" ]
      ]
    end
  end

  # Get recipient options for select
  def recipient_options
    # In a real application, this would fetch actual recipients
    # For now, we'll use dummy data
    [
      [ "John Doe (Wallet ID: 12345)", 1 ],
      [ "Jane Smith (Wallet ID: 67890)", 2 ],
      [ "Kwame Nkrumah (Wallet ID: 24680)", 3 ]
    ]
  end

  # Get merchant options for select
  def merchant_options
    # In a real application, this would fetch actual merchants
    # For now, we'll use dummy data
    [
      [ "Ghana Water Company", 4 ],
      [ "Electricity Company of Ghana", 5 ],
      [ "MTN Ghana", 6 ],
      [ "Vodafone Ghana", 7 ]
    ]
  end
end

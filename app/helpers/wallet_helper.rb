module WalletHelper
  def transaction_status_color(status)
    case status.to_s.downcase
    when "completed", "successful"
      "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
    when "pending"
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
    when "failed"
      "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
    else
      "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400"
    end
  end

  def bill_type_icon(type)
    case type.to_s.downcase
    when "electricity"
      "zap"
    when "water"
      "droplets"
    when "internet", "data"
      "wifi"
    when "airtime"
      "phone"
    when "tv"
      "tv"
    when "gas"
      "flame"
    when "insurance"
      "shield-check"
    when "loan"
      "landmark"
    when "mortgage"
      "building"
    when "education"
      "book-open"
    else
      "file-text"
    end
  end

  def transaction_type_color_class(type)
    case type.to_s.downcase
    when "deposit"
      "bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400"
    when "withdrawal"
      "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
    when "transfer"
      "bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400"
    when "bill_payment"
      "bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400"
    else
      "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400"
    end
  end

  def transaction_type_icon(type)
    case type.to_s.downcase
    when "deposit"
      "arrow-down-circle"
    when "withdrawal"
      "arrow-up-circle"
    when "transfer"
      "arrow-left-right"
    when "bill_payment"
      "receipt"
    else
      "circle"
    end
  end

  def transaction_amount_color_class(transaction)
    if transaction.transaction_type.to_s.downcase == "deposit" ||
       (transaction.destination_wallet_id == @wallet&.id && transaction.transaction_type.to_s.downcase == "transfer")
      "text-green-600 dark:text-green-400"
    else
      "text-red-600 dark:text-red-400"
    end
  end

  def transaction_amount_prefix(transaction)
    if transaction.transaction_type.to_s.downcase == "deposit" ||
       (transaction.destination_wallet_id == @wallet&.id && transaction.transaction_type.to_s.downcase == "transfer")
      "+"
    else
      "-"
    end
  end

  def transaction_recipient_info(transaction)
    if transaction.recipient_name.present?
      "To: #{transaction.recipient_name}"
    elsif transaction.source_name.present?
      "From: #{transaction.source_name}"
    else
      transaction.transaction_type.to_s.titleize
    end
  end

  # Helper for bill payment icons in the dashboard
  def bill_payment_icon(type)
    case type.to_s.downcase
    when "electricity"
      icon("zap", class: "w-6 h-6")
    when "water"
      icon("droplets", class: "w-6 h-6")
    when "internet", "data"
      icon("wifi", class: "w-6 h-6")
    when "airtime"
      icon("phone", class: "w-6 h-6")
    when "tv"
      icon("tv", class: "w-6 h-6")
    when "gas"
      icon("flame", class: "w-6 h-6")
    when "insurance"
      icon("shield-check", class: "w-6 h-6")
    when "loan"
      icon("landmark", class: "w-6 h-6")
    when "mortgage"
      icon("building", class: "w-6 h-6")
    when "education"
      icon("book-open", class: "w-6 h-6")
    when "more"
      icon("grid", class: "w-6 h-6")
    else
      icon("file-text", class: "w-6 h-6")
    end
  end
end

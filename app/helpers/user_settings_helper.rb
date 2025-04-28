module UserSettingsHelper
  # Helper method for payment method type colors
  def method_type_color(method_type)
    return "bg-gray-500" if method_type.blank?
    
    case method_type.to_s
    when "bank"
      "bg-blue-500"
    when "card"
      "bg-purple-500"
    when "mobile_money"
      "bg-green-500"
    when "wallet"
      "bg-amber-500"
    else
      "bg-gray-500"
    end
  end
  
  # Helper method for payment method status colors
  def method_status_color(status)
    case status.to_s
    when "verified"
      "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
    when "pending"
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
    when "rejected"
      "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
    when "expired"
      "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    else
      "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end
end

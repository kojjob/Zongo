module FlashHelper
  # Helper method to get the background color for the flash header
  def flash_background_color(type)
    case type.to_s
    when "success"
      "bg-green-100 dark:bg-green-800"
    when "error", "alert"
      "bg-red-100 dark:bg-red-800"
    when "warning"
      "bg-yellow-100 dark:bg-yellow-800"
    else # notice, info
      "bg-blue-100 dark:bg-blue-800"
    end
  end

  # Helper method to get the text color for the flash title
  def flash_text_color(type)
    case type.to_s
    when "success"
      "text-green-800 dark:text-green-100"
    when "error", "alert"
      "text-red-800 dark:text-red-100"
    when "warning"
      "text-yellow-800 dark:text-yellow-100"
    else # notice, info
      "text-blue-800 dark:text-blue-100"
    end
  end

  # Helper method to get the message text color
  def flash_message_color(type)
    case type.to_s
    when "success"
      "text-green-700 dark:text-green-200"
    when "error", "alert"
      "text-red-700 dark:text-red-200"
    when "warning"
      "text-yellow-700 dark:text-yellow-200"
    else # notice, info
      "text-blue-700 dark:text-blue-200"
    end
  end

  # Helper method to get the close button color
  def flash_close_button_color(type)
    case type.to_s
    when "success"
      "text-green-500 dark:text-green-300"
    when "error", "alert"
      "text-red-500 dark:text-red-300"
    when "warning"
      "text-yellow-500 dark:text-yellow-300"
    else # notice, info
      "text-blue-500 dark:text-blue-300"
    end
  end

  # Helper method to get the progress bar color
  def flash_progress_color(type)
    case type.to_s
    when "success"
      "bg-green-500"
    when "error", "alert"
      "bg-red-500"
    when "warning"
      "bg-yellow-500"
    else # notice, info
      "bg-blue-500"
    end
  end

  # Helper method to get the title for each flash type
  def flash_title(type)
    case type.to_s
    when "success"
      "Success"
    when "error"
      "Error"
    when "alert"
      "Alert"
    when "warning"
      "Warning"
    when "notice"
      "Notice"
    else
      "Information"
    end
  end

  # Helper method to get the icon for each flash type
  def flash_icon(type)
    case type.to_s
    when "success"
      '<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>'.html_safe
    when "error", "alert"
      '<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>'.html_safe
    when "warning"
      '<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>'.html_safe
    else # notice, info
      '<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>'.html_safe
    end
  end
end

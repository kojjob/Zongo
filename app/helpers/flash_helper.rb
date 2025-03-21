module FlashHelper
  # Define the flash type to CSS class mapping
  FLASH_CLASSES = {
    notice: "bg-blue-50 border-blue-300 text-blue-800 dark:bg-blue-900/20 dark:border-blue-800 dark:text-blue-300",
    success: "bg-green-50 border-green-300 text-green-800 dark:bg-green-900/20 dark:border-green-800 dark:text-green-300",
    error: "bg-red-50 border-red-300 text-red-800 dark:bg-red-900/20 dark:border-red-800 dark:text-red-300",
    alert: "bg-yellow-50 border-yellow-300 text-yellow-800 dark:bg-yellow-900/20 dark:border-yellow-800 dark:text-yellow-300",
    warning: "bg-yellow-50 border-yellow-300 text-yellow-800 dark:bg-yellow-900/20 dark:border-yellow-800 dark:text-yellow-300",
    info: "bg-blue-50 border-blue-300 text-blue-800 dark:bg-blue-900/20 dark:border-blue-800 dark:text-blue-300"
  }.freeze

  # Define the icon for each flash type
  FLASH_ICONS = {
    notice: "info",
    success: "check",
    error: "alert",
    alert: "alert",
    warning: "alert",
    info: "info"
  }.freeze

  # Render flash messages with appropriate styling
  def render_flash(flash_type, message)
    flash_type = flash_type.to_sym
    css_class = FLASH_CLASSES[flash_type] || FLASH_CLASSES[:notice]
    icon_name = FLASH_ICONS[flash_type] || "info"

    content_tag :div, class: "mb-4 p-4 rounded-md border #{css_class} animate-fade-in",
                data: { controller: "auto-dismiss", "auto-dismiss-target": "flash", "auto-dismiss-timeout": 5000 } do
      content_tag :div, class: "flex items-start" do
        concat(
          content_tag(:div, class: "flex-shrink-0") do
            icon(icon_name, class: "h-5 w-5")
          end
        )

        concat(
          content_tag(:div, class: "ml-3 w-full") do
            content_tag(:p, message, class: "text-sm")
          end
        )

        concat(
          content_tag(:div, class: "ml-auto pl-3") do
            content_tag(:div, class: "-mx-1.5 -my-1.5") do
              button_tag type: "button",
                        class: "inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-opacity-50",
                        data: { action: "click->auto-dismiss#dismiss" } do
                icon("close", class: "h-4 w-4")
              end
            end
          end
        )
      end
    end
  end
end

module ApplicationHelper
  # Include Pagy for pagination if available
  begin
    require "pagy"
    include Pagy::Frontend
  rescue LoadError
    # Helper methods for compatibility
  end

  # Helper method to render an icon from our SVG sprite
  def icon(name, options = {})
    options[:class] ||= ""
    content_tag :svg, options do
      content_tag :use, nil, "xlink:href" => "#icon-#{name}"
    end
  end

  # Helper method to render flash messages with appropriate styling
  def render_flash(type, message)
    # Convert flash type to appropriate style
    style = case type.to_sym
    when :success
              "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 border-green-200 dark:border-green-800"
    when :error
              "bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 border-red-200 dark:border-red-800"
    when :alert, :warning
              "bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200 border-yellow-200 dark:border-yellow-800"
    when :notice, :info
              "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 border-blue-200 dark:border-blue-800"
    else
              "bg-gray-100 dark:bg-gray-900 text-gray-800 dark:text-gray-200 border-gray-200 dark:border-gray-800"
    end

    # Icon based on type
    icon_name = case type.to_sym
    when :success
                 "check-circle"
    when :error
                 "x-circle"
    when :alert, :warning
                 "exclamation"
    when :notice, :info
                 "information-circle"
    else
                 "bell"
    end

    # Render the flash message
    content_tag :div, class: "p-4 rounded-lg border #{style} flex items-start relative" do
      concat content_tag(:div, icon(icon_name, class: "h-5 w-5 mr-3 flex-shrink-0"), class: "flex-shrink-0")
      concat content_tag(:div, message, class: "flex-1")

      # Add a close button
      concat(content_tag(:button, class: "ml-auto flex-shrink-0 -mr-1 -mt-1 p-1 rounded-full hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white/20", 'data-action': "click->flash#dismiss") do
        icon("x", class: "h-4 w-4")
      end)
    end
  end
end

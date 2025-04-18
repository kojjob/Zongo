module ApplicationHelper
  # Helper methods to provide Devise paths even in class contexts
  def registration_path(scope = :user)
    "/#{scope.to_s.pluralize}/sign_up"
  end

  def new_user_registration_path
    registration_path(:user)
  end

  def user_registration_path
    registration_path(:user)
  end

  def session_path(scope = :user)
    "/#{scope.to_s.pluralize}/sign_in"
  end

  def new_user_session_path
    session_path(:user)
  end

  def user_session_path
    session_path(:user)
  end

  def destroy_user_session_path
    "/users/sign_out"
  end

  def edit_user_registration_path
    "/users/edit"
  end
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

  # Helper method to get SVG path for category icons
  def get_icon_path(icon_name)
    case icon_name.to_s
    when "music"
      "M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"
    when "activity", "sports"
      "M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11"
    when "utensils", "food"
      "M21 15.546c-.523 0-1.046.151-1.5.454a2.704 2.704 0 01-3 0 2.704 2.704 0 00-3 0 2.704 2.704 0 01-3 0 2.704 2.704 0 00-3 0 2.704 2.704 0 01-3 0 2.701 2.701 0 00-1.5-.454M9 6v2m3-2v2m3-2v2M9 3h.01M12 3h.01M15 3h.01M21 21v-7a2 2 0 00-2-2H5a2 2 0 00-2 2v7h18zm-3-9v-2a2 2 0 00-2-2H8a2 2 0 00-2 2v2h12z"
    when "code", "technology"
      "M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
    when "briefcase", "business"
      "M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
    when "book-open", "education"
      "M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
    when "users", "community"
      "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
    when "heart", "health"
      "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
    else
      "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
    end
  end

  # Helper function for transaction status colors
  def transaction_status_color(status)
    case status.to_s.downcase
    when "completed"
      "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
    when "pending"
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
    when "failed"
      "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
    else
      "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400"
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

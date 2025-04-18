class NavigationService
  def self.main_navigation(user = nil)
    items = NavigationItem.root_items.active.by_position

    if user
      items = items.select { |item| item.visible_for?(user) }
    else
      items = items.reject(&:requires_auth?)
    end

    items.map do |item|
      child_items = item.children.active.by_position.select { |child| child.visible_for?(user) }

      {
        id: item.id,
        title: item.title,
        path: item.path,
        icon: item.icon,
        children: child_items.map { |child|
          {
            id: child.id,
            title: child.title,
            path: child.path,
            icon: child.icon
          }
        }
      }
    end
  end

  # For mobile navigation which might have different structure
  def self.mobile_navigation(user = nil)
    main_navigation(user)
  end

  # Determine if the current path matches this navigation item
  def self.active_item?(item, current_path)
    return false unless item && current_path

    # Exact match
    return true if current_path == item[:path]

    # Check if this is a parent of the current path
    if item[:children].present?
      item[:children].any? { |child| current_path == child[:path] }
    else
      # For sections, check if the current path starts with this path
      # But only if the path is not just "/"
      item[:path] != "/" && current_path.start_with?(item[:path])
    end
  end

  # Find the currently active navigation item based on the path
  def self.find_active_item(items, current_path)
    items.find { |item| active_item?(item, current_path) }
  end
end

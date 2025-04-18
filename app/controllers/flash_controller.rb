class FlashController < ApplicationController
  # No authentication needed for flash actions

  # Clear flash messages
  def clear
    # Clear all flash messages
    flash.clear

    # Redirect back to the previous page
    redirect_back(fallback_location: root_path)
  end
end

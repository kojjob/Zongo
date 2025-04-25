class Admin::HelpController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  layout "admin"

  def index
    # Render the help center page
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "You don't have permission to access this page."
    end
  end
end

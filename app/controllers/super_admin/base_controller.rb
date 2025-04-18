module SuperAdmin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_super_admin
    layout "admin"

    private

    def require_super_admin
      unless current_user.super_admin?
        redirect_to root_path, alert: "You don't have permission to access this page. Super Admin privileges required."
      end
    end
  end
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Backend
  include FlashHelper
  # Add and expose all Devise path helpers
  helper_method :new_user_registration_path, :new_user_session_path, :user_session_path,
                :destroy_user_session_path, :edit_user_registration_path, :user_registration_path

  # Add debugging to diagnose current_user type issues
  before_action :log_current_user_type

  def log_current_user_type
    if current_user
      Rails.logger.debug "CURRENT_USER_DEBUG: Type is #{current_user.class.name} in #{controller_name}##{action_name}"
      if current_user.is_a?(Hash)
        Rails.logger.debug "CURRENT_USER_DEBUG: Hash keys: #{current_user.keys.join(', ')}"
        Rails.logger.debug "CURRENT_USER_DEBUG: Hash data: #{current_user.inspect}"
        begin
          stack = caller.join("\n  ")
          Rails.logger.debug "CURRENT_USER_DEBUG: Call stack:\n  #{stack}"
        rescue => e
          Rails.logger.debug "CURRENT_USER_DEBUG: Cannot log stack trace: #{e.message}"
        end
      end
    end
  end

  # Override current_user to always return a User object, not a Hash
  def current_user
    @current_user ||= begin
      original_user = begin
        super
      rescue => e
        logger.error "Error in current_user super: #{e.message}"
        nil
      end

      if original_user.is_a?(Hash)
        # If current_user is a Hash, find the actual User object
        user_id = original_user[:id] || original_user["id"]
        logger.info "Converting Hash current_user to User object (ID: #{user_id})"
        User.find_by(id: user_id)
      else
        original_user
      end
    end
  end

  # Override authenticate_user! to handle errors
  def authenticate_user!
    begin
      super
    rescue => e
      logger.error "Error in authenticate_user!: #{e.message}"
      # Redirect to sign in page
      redirect_to new_user_session_path, alert: "Please sign in to continue"
    end
  end

  # Override Devise's method to handle already authenticated users
  def require_no_authentication
    return unless is_navigational_format?

    if user_signed_in?
      # If trying to access profile or settings, just go there instead of showing error
      if request.path.match?(/\/(profile|settings|user_settings)/)
        redirect_to profile_path
        return
      end

      # For other authentication pages, use the default behavior
      set_flash_message(:alert, "already_authenticated")
      redirect_to after_sign_in_path_for(current_user)
    end
  end

  # Define Devise path methods based on routes configuration
  def new_user_registration_path
    "/users/sign_up"
  end

  def new_user_session_path
    "/users/sign_in"
  end

  def user_session_path
    "/users/sign_in"
  end

  def destroy_user_session_path
    "/users/sign_out"
  end

  def edit_user_registration_path
    "/users/edit"
  end

  def user_registration_path
    "/users/sign_up"
  end

  # Define the session_path for all scopes
  def session_path(scope)
    "/#{scope.to_s.pluralize}/sign_in"
  end
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Admin helper method
  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "You don't have permission to access this page."
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :phone, :name, :username, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :phone, :name, :username, :avatar ])
  end

  # Action to clear flash messages
  def clear_flash
    # Clear all flash messages
    flash.clear

    # Redirect back to the previous page
    redirect_back(fallback_location: root_path)
  end
end

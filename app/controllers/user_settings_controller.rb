class UserSettingsController < ApplicationController
  # Handle authentication errors
  def authenticate_user!
    begin
      super
    rescue => e
      logger.error "Error in UserSettingsController authenticate_user!: #{e.message}"
      redirect_to new_user_session_path, alert: "Please sign in to access your settings"
    end
  end

  before_action :authenticate_user!
  before_action :set_user

  # Main settings page with tabs
  def index
    # Template will be automatically rendered from app/views/user_settings/index.html.erb
  end

  # Profile settings
  def profile
    # Template will be automatically rendered from app/views/user_settings/profile.html.erb
  end

  # Security settings
  def security
    # Template will be automatically rendered from app/views/user_settings/security.html.erb
  end

  # Notification preferences
  def notifications
    # Template will be automatically rendered from app/views/user_settings/notifications.html.erb
  end

  # Appearance & theme settings
  def appearance
    # Template will be automatically rendered from app/views/user_settings/appearance.html.erb
  end

  # Wallet & payment settings
  def payment
    @payment_methods = current_user.payment_methods.order(default: :desc)
    # Template will be automatically rendered from app/views/user_settings/payment.html.erb
  end

  # Support & help
  def support
    # Template will be automatically rendered from app/views/user_settings/support.html.erb
  end

    # Update profile information
    def update_profile
        # Add additional error handling
        begin
        if @user.update(profile_params)
            flash[:success] = "Profile updated successfully"
            redirect_to user_settings_profile_path
        else
            # Log validation errors
            Rails.logger.error @user.errors.full_messages
            render :edit
        end
        rescue ActiveSupport::MessageVerifier::InvalidSignature => e
        # Log the specific error
        Rails.logger.error "Session verification error: #{e.message}"
        flash[:error] = "There was an issue updating your profile. Please try again."
        redirect_to user_settings_profile_path
        end
    end

  # Update security settings
  def update_security
    # First check if current password is correct
    if @user.valid_password?(params[:current_password])
      # Check if we're updating password
      if params[:user][:password].present?
        if @user.update(security_params)
          bypass_sign_in(@user)
          flash[:success] = "Password updated successfully"
          redirect_to user_settings_security_path
        else
          flash.now[:error] = "Failed to update password: #{@user.errors.full_messages.join(', ')}"
          render "security"
        end
      else
        flash.now[:error] = "New password cannot be blank"
        render "security"
      end
    else
      flash.now[:error] = "Current password is incorrect"
      render "security"
    end
  end

  # Update notification preferences
  def update_notifications
    # Ensure setting exists
    @user.create_setting if @user.setting.nil?

    if @user.setting.update(notification_params)
      flash[:success] = "Notification preferences updated"
      redirect_to user_settings_notifications_path
    else
      flash.now[:error] = "Failed to update notification preferences"
      render "notifications"
    end
  end

  # Update appearance settings
  def update_appearance
    # Ensure user has settings
    @user.create_setting if @user.setting.nil?

    # Get theme preference from params
    theme_preference = params[:user][:settings][:theme_preference] if params[:user][:settings].present?
    language = params[:user][:settings][:language] if params[:user][:settings].present?
    currency_display = params[:user][:settings][:currency_display] if params[:user][:settings].present?

    # Update settings
    if @user.setting.update(
        theme_preference: theme_preference,
        language: language,
        currency_display: currency_display
      )
      flash[:success] = "Appearance settings updated"
      redirect_to user_settings_appearance_path
    else
      flash.now[:error] = "Failed to update appearance settings"
      render "appearance"
    end
  end

  # Toggle a specific setting on/off
  def toggle_setting
    setting_name = params[:setting_name]
    current_value = @user.settings[setting_name]

    @user.settings[setting_name] = !current_value

    if @user.save
      render json: { success: true, value: !current_value }
    else
      render json: { success: false, error: "Failed to update setting" }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    begin
      @user = current_user

      # Handle case where current_user is nil
      unless @user
        logger.error "Current user is nil in UserSettingsController"
        redirect_to new_user_session_path, alert: "Please sign in to access your settings"
        return
      end

      # Ensure user has a setting record
      @user.create_setting if @user.setting.nil?
    rescue => e
      logger.error "Error in set_user: #{e.message}"
      redirect_to new_user_session_path, alert: "An error occurred. Please sign in again."
    end
  end

  def profile_params
    params.require(:user).permit(:username, :email, :first_name, :last_name, :phone, :avatar)
  end

  def security_params
    params.require(:user).permit(:password, :password_confirmation)
  end

    def notification_params
      params.require(:user_setting).permit(
          :email_notifications,
          :sms_notifications,
          :push_notifications,
          :deposit_alerts,
          :withdrawal_alerts,
          :transfer_alerts,
          :low_balance_alerts,
          :login_alerts,
          :password_alerts,
          :product_updates,
          :promotional_emails
      )
    end

  # We're not using this since we now directly update the settings
  # def appearance_params
  #     params.require(:user).permit(
  #     settings: [
  #         :theme_preference,
  #         :language,
  #         :currency_display
  #     ]
  #     )
  # end
end

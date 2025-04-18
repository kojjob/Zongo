class SecuritySettingsController < ApplicationController
  before_action :authenticate_user!

  # Show security settings page
  def index
    @has_pin_set = current_user.pin_digest.present?
    @recent_activities = SecurityLog.where(user_id: current_user.id)
                                   .order(created_at: :desc)
                                   .limit(10)
    # Ensure user settings exist
    current_user.user_settings || current_user.create_user_settings
  end

  # Set up or change PIN
  def set_pin
    # Validate current password for security
    unless current_user.valid_password?(params[:current_password])
      flash[:error] = "Current password is incorrect"
      redirect_to security_settings_path
      return
    end

    # Validate PIN
    pin = params[:pin]
    pin_confirmation = params[:pin_confirmation]

    if pin.blank? || pin.length < 4 || pin.length > 6 || pin !~ /^\d+$/
      flash[:error] = "PIN must be 4-6 digits"
      redirect_to security_settings_path
      return
    end

    if pin != pin_confirmation
      flash[:error] = "PIN confirmation doesn't match"
      redirect_to security_settings_path
      return
    end

    # Set the PIN
    if current_user.set_pin(pin)
      # Log the PIN change
      SecurityLog.log_event(
        current_user,
        :password_change,
        severity: :info,
        details: { action: current_user.pin_digest.present? ? "PIN changed" : "PIN created" },
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      flash[:success] = "Transaction PIN has been set successfully"
    else
      flash[:error] = "Failed to set PIN"
    end

    redirect_to security_settings_path
  end

  # Remove PIN
  def remove_pin
    # Validate current password for security
    unless current_user.valid_password?(params[:current_password])
      flash[:error] = "Current password is incorrect"
      redirect_to security_settings_path
      return
    end

    # Remove the PIN
    current_user.update(pin_digest: nil)

    # Log the PIN removal
    SecurityLog.log_event(
      current_user,
      :password_change,
      severity: :info,
      details: { action: "PIN removed" },
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    flash[:success] = "Transaction PIN has been removed"
    redirect_to security_settings_path
  end

  # View all security logs
  def activity_logs
    @pagy, @logs = pagy(
      SecurityLog.where(user_id: current_user.id)
                 .order(created_at: :desc),
      items: 20
    )
  end

  # Lock account in case of suspicious activity
  def lock_account
    # Validate current password for security
    unless current_user.valid_password?(params[:current_password])
      flash[:error] = "Current password is incorrect"
      redirect_to security_settings_path
      return
    end

    # Lock the account
    current_user.update(status: :locked)

    # Log the action
    SecurityLog.log_event(
      current_user,
      :account_locked,
      severity: :warning,
      details: {
        reason: "User initiated",
        action: "Account locked",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    )

    # Sign the user out
    sign_out current_user

    flash[:notice] = "Your account has been locked for security. Please contact support to unlock."
    redirect_to new_user_session_path
  end

  # Update security preferences
  def update_preferences
    # Get or create user settings
    user_settings = current_user.user_settings || current_user.create_user_settings

    # Update login notification settings
    user_settings.update(
      login_alerts: params[:login_alerts] == "1",
      password_alerts: params[:password_alerts] == "1",
      withdrawal_alerts: params[:withdrawal_alerts] == "1",
      transfer_alerts: params[:transfer_alerts] == "1"
    )

    flash[:success] = "Security preferences updated successfully"
    redirect_to security_settings_path
  end
end

class UserSettingsController < ApplicationController
  # We'll use the ApplicationController's authenticate_user! method instead

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
      # Handle avatar upload separately
      if params[:user] && params[:user][:avatar].present?
        Rails.logger.info "Attempting to attach avatar: #{params[:user][:avatar].inspect}"
        Rails.logger.info "Avatar content type: #{params[:user][:avatar].content_type}" if params[:user][:avatar].respond_to?(:content_type)
        Rails.logger.info "Avatar size: #{params[:user][:avatar].size}" if params[:user][:avatar].respond_to?(:size)

        begin
          # Check if the file is valid
          if params[:user][:avatar].respond_to?(:content_type) &&
             !params[:user][:avatar].content_type.in?(%w[image/jpeg image/png image/jpg])
            flash[:error] = "Invalid file type. Please upload a JPEG or PNG image."
            return render :profile
          end

          # Check file size (max 5MB)
          if params[:user][:avatar].respond_to?(:size) &&
             params[:user][:avatar].size > 5.megabytes
            flash[:error] = "File size exceeds 5MB. Please choose a smaller image."
            return render :profile
          end

          # Purge existing avatar if present
          @user.avatar.purge if @user.avatar.attached?

          # Attach the new avatar
          @user.avatar.attach(params[:user][:avatar])
          Rails.logger.info "Avatar attached successfully"
        rescue => e
          Rails.logger.error "Error attaching avatar: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          flash[:error] = "Failed to upload image: #{e.message}"
          return render :profile
        end
      end

      # Update user settings if present
      if params[:user] && params[:user][:settings].present?
        # Ensure user has user_settings
        @user.create_user_settings if @user.user_settings.nil?

        # Update settings with lowercase values to match the enum
        language = params[:user][:settings][:language]&.downcase
        currency_display = params[:user][:settings][:currency_display]&.downcase

        # Log the values for debugging
        Rails.logger.info "Updating user settings with language: #{language}, currency_display: #{currency_display}"

        @user.user_settings.update(
          language: language,
          currency_display: currency_display
        )
      end

      # Update user attributes
      if @user.update(profile_params)
        # Log the successful profile update
        SecurityLog.log_event(
          @user,
          :profile_updated,
          severity: :info,
          details: {
            updated_fields: profile_params.keys,
            ip_address: request.remote_ip
          }
        )

        flash[:success] = "Profile updated successfully"
        redirect_to profile_path
      else
        # Log validation errors
        Rails.logger.error @user.errors.full_messages
        flash.now[:error] = @user.errors.full_messages.join(", ")
        render :profile
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      # Log the specific error
      Rails.logger.error "Session verification error: #{e.message}"
      flash[:error] = "There was an issue updating your profile. Please try again."
      redirect_to profile_path
    rescue => e
      # Log any other errors
      Rails.logger.error "Error updating profile: #{e.message}"
      flash[:error] = "An unexpected error occurred. Please try again."
      redirect_to profile_path
    end
  end

  # Remove avatar
  def remove_avatar
    if @user.avatar.attached?
      @user.avatar.purge
      flash[:success] = "Profile picture removed"
    else
      flash[:notice] = "No profile picture to remove"
    end
    redirect_to profile_path
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
    # Ensure user_settings exists
    @user.create_user_settings if @user.user_settings.nil?

    if @user.user_settings.update(notification_params)
      flash[:success] = "Notification preferences updated"
      redirect_to user_settings_notifications_path
    else
      flash.now[:error] = "Failed to update notification preferences"
      render "notifications"
    end
  end

  # Update appearance settings
  def update_appearance
    # Ensure user has user_settings
    @user.create_user_settings if @user.user_settings.nil?

    # Get settings from params
    if params[:user] && params[:user][:settings].present?
      # Get values from params and ensure they're lowercase for enum compatibility
      theme_preference = params[:user][:settings][:theme_preference]&.downcase

      # Map 'system' to 'auto' if needed (for backward compatibility)
      theme_preference = 'auto' if theme_preference == 'system'

      language = params[:user][:settings][:language]&.downcase
      currency_display = params[:user][:settings][:currency_display]&.downcase
      text_size = params[:user][:settings][:text_size]
      reduce_motion = params[:user][:settings][:reduce_motion]
      high_contrast = params[:user][:settings][:high_contrast]

      # Log the values for debugging
      Rails.logger.info "Updating appearance settings with: theme_preference=#{theme_preference}, language=#{language}, currency_display=#{currency_display}, text_size=#{text_size}, reduce_motion=#{reduce_motion}, high_contrast=#{high_contrast}"

      # Log the current user settings before update
      Rails.logger.info "Current user settings before update: theme_preference=#{@user.user_settings.theme_preference}, language=#{@user.user_settings.language}, currency_display=#{@user.user_settings.currency_display}"

      # Update settings
      update_params = {}
      update_params[:theme_preference] = theme_preference if theme_preference.present?
      update_params[:language] = language if language.present?
      update_params[:currency_display] = currency_display if currency_display.present?
      update_params[:text_size] = text_size if text_size.present?
      update_params[:reduce_motion] = reduce_motion == "1" || reduce_motion == "true" if reduce_motion.present?
      update_params[:high_contrast] = high_contrast == "1" || high_contrast == "true" if high_contrast.present?

      result = @user.user_settings.update(update_params)

      # Log the result and user settings after update
      Rails.logger.info "Update result: #{result}"
      Rails.logger.info "User settings after update: theme_preference=#{@user.user_settings.reload.theme_preference}, language=#{@user.user_settings.language}, currency_display=#{@user.user_settings.currency_display}"

      # Respond to the request format
      respond_to do |format|
        format.html {
          if result
            flash[:success] = "Appearance settings updated"

            # Redirect based on the referring page
            if request.referer&.include?('profile')
              redirect_to user_settings_profile_path
            else
              redirect_to user_settings_appearance_path
            end
          else
            flash.now[:error] = "Failed to update appearance settings: #{@user.user_settings.errors.full_messages.join(', ')}"

            # Render the appropriate template based on the referring page
            if request.referer&.include?('profile')
              render "profile"
            else
              render "appearance"
            end
          end
        }
        format.json {
          if result
            render json: { success: true, message: "Appearance settings updated", settings: @user.user_settings }
          else
            render json: { success: false, message: "Failed to update appearance settings", errors: @user.user_settings.errors.full_messages }, status: :unprocessable_entity
          end
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = "No settings provided"
          redirect_back(fallback_location: user_settings_path)
        }
        format.json {
          render json: { success: false, message: "No settings provided" }, status: :unprocessable_entity
        }
      end
    end
  end

  # Toggle a specific setting on/off
  def toggle_setting
    setting_name = params[:setting_name]
    value = params[:value]

    # Ensure user has user_settings
    @user.create_user_settings if @user.user_settings.nil?

    # Log the request
    Rails.logger.info "Toggle setting request: setting_name=#{setting_name}, value=#{value}"

    # Validate the setting name
    unless @user.user_settings.respond_to?(setting_name)
      render json: { success: false, error: "Invalid setting name: #{setting_name}" }, status: :unprocessable_entity
      return
    end

    # Get current value from user_settings
    current_value = @user.user_settings.send(setting_name)

    # Determine the new value
    new_value = if value.present?
      # Convert string value to boolean
      value == "true" || value == "1"
    else
      # Toggle the current value
      !current_value
    end

    # Log the values
    Rails.logger.info "Toggling setting #{setting_name} from #{current_value} to #{new_value}"

    # Update the setting
    if @user.user_settings.update(setting_name => new_value)
      render json: {
        success: true,
        setting: setting_name,
        value: new_value,
        message: "Setting updated successfully"
      }
    else
      render json: {
        success: false,
        error: "Failed to update setting",
        errors: @user.user_settings.errors.full_messages
      }, status: :unprocessable_entity
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

      # Ensure user has a user_settings record
      @user.create_user_settings if @user.user_settings.nil?
    rescue => e
      logger.error "Error in set_user: #{e.message}"
      redirect_to new_user_session_path, alert: "An error occurred. Please sign in again."
    end
  end

  def profile_params
    params.require(:user).permit(
      :username,
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :bio,
      :date_of_birth,
      :gender,
      :address,
      :city,
      :state,
      :country,
      :postal_code,
      :website,
      :occupation
    )
  end

  def security_params
    params.require(:user).permit(:password, :password_confirmation)
  end

    def notification_params
      params.require(:user_settings).permit(
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

class Users::PasswordsController < Devise::PasswordsController
  # Add a before_action to ensure the Devise mapping is set for custom actions
  before_action :set_devise_mapping, only: [ :reset_success, :instructions_sent ]

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    # Find the user by email
    user = User.find_by(email: resource_params[:email])

    # Always show success message even if email doesn't exist (security best practice)
    if user.present?
      # Only send instructions if the user exists
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
    else
      # Create a new resource for the view but don't send email
      self.resource = resource_class.new(resource_params)
    end

    # Always redirect to the same page with a success message
    # This prevents user enumeration attacks
    flash[:notice] = I18n.t("devise.passwords.send_instructions")
    redirect_to after_sending_reset_password_instructions_path_for(resource_name)
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    begin
      # Check if the token is valid
      reset_password_token = params[:reset_password_token]
      if reset_password_token.blank? || !valid_reset_password_token?(reset_password_token)
        Rails.logger.info("Invalid or expired reset password token: #{reset_password_token}")
        render "invalid_token" and return
      end

      super
    rescue => e
      # Handle any errors
      Rails.logger.error("Error in password reset: #{e.message}\n#{e.backtrace.join("\n")}")
      # Handle invalid or expired token
      render "invalid_token"
    end
  end

  # PUT /resource/password
  def update
    begin
      self.resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?

      if resource.errors.empty?
        resource.unlock_access! if unlockable?(resource)
        if Devise.sign_in_after_reset_password
          flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
          set_flash_message!(:notice, flash_message)
          resource.after_database_authentication
          sign_in(resource_name, resource)
          respond_with resource, location: after_resetting_password_path_for(resource)
        else
          set_flash_message!(:notice, :updated_not_active)
          respond_with resource, location: new_session_path(resource_name)
        end
      else
        set_minimum_password_length
        respond_with resource
      end
    rescue => e
      # Log the error
      Rails.logger.error("Error updating password: #{e.message}\n#{e.backtrace.join("\n")}")

      # Create a new resource with the submitted parameters
      self.resource = resource_class.new
      resource.errors.add(:base, "There was an error resetting your password. Please try again.")

      # Set minimum password length for the view
      set_minimum_password_length

      # Render the form again
      respond_with resource
    end
  end

  # The path used after sending reset password instructions
  def after_sending_reset_password_instructions_path_for(resource_name)
    password_instructions_sent_path if is_navigational_format?
  end

  # The path used after resetting the password
  def after_resetting_password_path_for(resource)
    password_reset_success_path
  end

  # GET /resource/password/reset_success
  def reset_success
    # Ensure the Devise mapping is set correctly
    self.resource = resource_class.new
    # This action renders the reset_success.html.erb template
  end

  # GET /resource/password/instructions_sent
  def instructions_sent
    # Ensure the Devise mapping is set correctly
    self.resource = resource_class.new
    # This action renders the instructions_sent.html.erb template
  end

  protected

  def translation_scope
    "devise.passwords"
  end

  # Set the Devise mapping for custom actions
  def set_devise_mapping
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Override the resource_params method to ensure parameters are properly permitted
  def resource_params
    if params[:user].present?
      params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
    else
      # Handle the case when params[:user] is not present (e.g., in custom actions)
      {}
    end
  end

  # Check if the reset password token is valid
  def valid_reset_password_token?(token)
    return false if token.blank?

    # Find user by reset password token
    reset_password_token = Devise.token_generator.digest(User, :reset_password_token, token)
    user = User.find_by(reset_password_token: reset_password_token)

    # Check if user exists and token is not expired
    return false unless user

    # Check if the token is expired
    reset_password_sent_at = user.reset_password_sent_at
    return false unless reset_password_sent_at

    # Make sure reset_password_sent_at is a Time object
    if reset_password_sent_at.is_a?(String)
      begin
        reset_password_sent_at = Time.parse(reset_password_sent_at)
      rescue
        return false
      end
    end

    # Check if the token is still valid (not expired)
    reset_password_sent_at > Devise.reset_password_within.ago
  rescue => e
    Rails.logger.error("Error validating reset password token: #{e.message}")
    false
  end
end

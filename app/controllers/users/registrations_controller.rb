class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  before_action :configure_permitted_parameters

  # Override current_user to handle the invalid strategy error
  def current_user
    begin
      super
    rescue => e
      logger.error "Error in RegistrationsController current_user: #{e.message}"
      nil
    end
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    begin
      super do |resource|
        # Add any custom processing here
        Rails.logger.info("Creating new user with parameters: #{sign_up_params.inspect}")
      end
    rescue => e
      # Handle the error gracefully
      Rails.logger.error("Error in user registration: #{e.message}")

      # Build a new user with the submitted parameters
      build_resource(sign_up_params)

      # Add a generic error message
      resource.errors.add(:base, "Registration failed. Please try again or contact support.")

      # Render the sign up form again
      respond_with resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # Configure permitted parameters for sign up and account update
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :phone, :username, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone, :username, :avatar ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end

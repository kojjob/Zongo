class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # Override current_user to handle the invalid strategy error
  def current_user
    begin
      super
    rescue => e
      logger.error "Error in SessionsController current_user: #{e.message}"
      nil
    end
  end

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    begin
      super do |resource|
        # Add any custom processing here
        Rails.logger.info("User signed in: #{resource.id}")
      end
    rescue => e
      # Handle the error gracefully
      Rails.logger.error("Error in user sign in: #{e.message}")

      # Build a new session with the submitted parameters
      self.resource = resource_class.new(sign_in_params)

      # Add a generic error message
      flash.now[:alert] = "Sign in failed. Please check your credentials and try again."

      # Render the sign in form again
      render :new
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
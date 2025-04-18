# This file provides fallback route helpers for Devise
# These helpers are used when the route helpers are not available in a class context

module DeviseRouteHelpers
  def self.included(base)
    base.class_eval do
      # Class methods for routes
      def self.new_user_registration_path
        "/users/sign_up"
      end

      def self.new_user_session_path
        "/users/sign_in"
      end

      def self.user_session_path
        "/users/sign_in"
      end

      def self.destroy_user_session_path
        "/users/sign_out"
      end

      def self.edit_user_registration_path
        "/users/edit"
      end

      def self.user_registration_path
        "/users/sign_up"
      end

      # Instance methods for consistency
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
    end
  end
end

# Include the helpers in Object to make them available everywhere
Object.include DeviseRouteHelpers

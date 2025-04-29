module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update, :destroy, :suspend, :activate, :promote, :demote ]

    def index
      @users = User.all.order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present?
        @users = @users.where(status: params[:status])
      end

      # Filter by role if provided
      if params[:role].present?
        if params[:role] == "admin"
          @users = @users.where(admin: true)
        elsif params[:role] == "super_admin"
          @users = @users.where(super_admin: true)
        elsif params[:role] == "regular"
          @users = @users.where(admin: false, super_admin: false)
        end
      end

      # Filter by search term if provided
      if params[:search].present?
        @users = @users.where("username LIKE ? OR email LIKE ? OR phone LIKE ?",
                             "%#{params[:search]}%",
                             "%#{params[:search]}%",
                             "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @users = pagy(@users, items: 10)
    end

    def show
      # Load user's recent activity
      @recent_transactions = @user.wallet.transactions.order(created_at: :desc).limit(5) if @user.wallet
      @recent_logins = @user.security_logs.where(event_type: "login").order(created_at: :desc).limit(5)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      # Generate a random password for the user
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
      @user.password_confirmation = generated_password

      if @user.save
        # Log the user creation
        SecurityLog.log_event(
          @user,
          :account_created,
          severity: :info,
          details: { created_by: current_user.id },
          loggable: @user
        )

        redirect_to admin_user_path(@user), notice: "User was successfully created. The temporary password is: #{generated_password}"
      else
        render :new
      end
    end

    def edit
    end

    def update
      # Log the parameters for debugging
      Rails.logger.debug "User update params: #{user_params.inspect}"

      if @user.update(user_params)
        # Log success
        Rails.logger.debug "User update successful"
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        # Log failure and errors
        Rails.logger.debug "User update failed: #{@user.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user.destroy
        # Log the user deletion
        SecurityLog.log_event(
          current_user,
          :account_deleted,
          severity: :warning,
          details: { deleted_user_id: @user.id, deleted_user_email: @user.email },
          ip_address: request.remote_ip
        )

        redirect_to admin_users_path, notice: "User was successfully deleted."
      else
        redirect_to admin_user_path(@user), alert: "Failed to delete user."
      end
    end

    def suspend
      if @user.update(status: :suspended)
        # Log the suspension
        SecurityLog.log_event(
          @user,
          :account_suspended,
          severity: :warning,
          details: { suspended_by: current_user.id },
          loggable: @user
        )

        redirect_to admin_user_path(@user), notice: "User has been suspended."
      else
        redirect_to admin_user_path(@user), alert: "Failed to suspend user."
      end
    end

    def activate
      if @user.update(status: :active)
        # Log the activation
        SecurityLog.log_event(
          @user,
          :account_activated,
          severity: :info,
          details: { activated_by: current_user.id },
          loggable: @user
        )

        redirect_to admin_user_path(@user), notice: "User has been activated."
      else
        redirect_to admin_user_path(@user), alert: "Failed to activate user."
      end
    end

    def promote
      if @user.update(admin: true)
        # Log the promotion
        SecurityLog.log_event(
          @user,
          :promoted_to_admin,
          severity: :warning,
          details: { promoted_by: current_user.id },
          loggable: @user
        )

        redirect_to admin_user_path(@user), notice: "User has been promoted to admin."
      else
        redirect_to admin_user_path(@user), alert: "Failed to promote user."
      end
    end

    def demote
      if @user.update(admin: false)
        # Log the demotion
        SecurityLog.log_event(
          @user,
          :demoted_from_admin,
          severity: :warning,
          details: { demoted_by: current_user.id },
          loggable: @user
        )

        redirect_to admin_user_path(@user), notice: "User has been demoted from admin."
      else
        redirect_to admin_user_path(@user), alert: "Failed to demote user."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      # Log the raw parameters for debugging
      Rails.logger.debug "Raw params: #{params.inspect}"

      # Only allow certain parameters to be updated
      permitted_params = [:username, :email, :phone, :kyc_level, :status]

      # Add admin parameter if the current user is an admin
      permitted_params << :admin if current_user.admin?

      # Add super_admin parameter if the current user is a super_admin
      permitted_params << :super_admin if current_user.super_admin?

      # Log the permitted parameters
      Rails.logger.debug "Permitted params: #{permitted_params.inspect}"

      # Return the permitted parameters
      params.require(:user).permit(permitted_params)
    end
  end
end

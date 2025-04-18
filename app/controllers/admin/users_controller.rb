module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_user, only: [ :show, :edit, :update, :suspend, :activate, :promote, :demote ]
    layout "admin"

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

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit
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
      # Only allow certain parameters to be updated
      params.require(:user).permit(:username, :email, :phone, :kyc_level, :status)
    end
  end
end

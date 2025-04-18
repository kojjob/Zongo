class Admin::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  layout "admin"

  def index
    # Get recent users for notifications
    @recent_users = User.order(created_at: :desc).limit(20)
    @new_users_today = User.where('created_at >= ?', Time.zone.now.beginning_of_day).count

    # Get recent transactions if the Transaction model exists
    if defined?(Transaction)
      @recent_transactions = Transaction.order(created_at: :desc).limit(20)
    end

    # Get recent events if the Event model exists
    if defined?(Event)
      @recent_events = Event.order(created_at: :desc).limit(20)
    end

    # Get unread contact submissions if the ContactSubmission model exists
    if defined?(ContactSubmission)
      @unread_contact_submissions = ContactSubmission.where(read: false).count
    end

    # Set the title for the layout
    @page_title = "Notifications"
  end

  private

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this page."
      redirect_to root_path
    end
  end
end

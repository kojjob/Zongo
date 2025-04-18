class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :show, :mark_as_read, :mark_as_unread, :dismiss ]

  # GET /notifications
  def index
    # Get filter parameters
    @filter_category = params[:category]
    @filter_read = params[:read]

    # Build query
    @notifications = current_user.notifications.recent_first

    # Apply category filter if specified
    if @filter_category.present?
      @notifications = @notifications.where(category: @filter_category)
    end

    # Apply read filter if specified
    if @filter_read.present?
      @notifications = @notifications.where(read: @filter_read == "true")
    end

    # Paginate results
    @pagy, @notifications = pagy(@notifications, items: 20)

    # Format response based on request type
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
      format.turbo_stream
    end
  end

  # GET /notifications/unread
  def unread
    @notifications = current_user.notifications.unread.recent_first

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @notifications }
      format.turbo_stream
    end
  end

  # GET /notifications/security
  def security
    @notifications = current_user.notifications.security.recent_first

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @notifications }
      format.turbo_stream
    end
  end

  # GET /notifications/:id
  def show
    # Mark notification as read
    @notification.mark_as_read!

    # Redirect to action URL if present, otherwise stay on notifications page
    if @notification.has_action?
      redirect_to @notification.action_url
    else
      redirect_to notifications_path
    end
  end

  # POST /notifications/:id/mark_as_read
  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  # POST /notifications/:id/mark_as_unread
  def mark_as_unread
    @notification.mark_as_unread!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    # Get scope based on parameters
    scope = current_user.notifications.unread

    # Apply category filter if specified
    if params[:category].present?
      scope = scope.where(category: params[:category])
    end

    # Mark all notifications in scope as read
    scope.update_all(read: true, read_at: Time.current)

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  # DELETE /notifications/:id
  def dismiss
    @notification.destroy

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  # DELETE /notifications/dismiss_all
  def dismiss_all
    # Get scope based on parameters
    scope = current_user.notifications

    # Apply category filter if specified
    if params[:category].present?
      scope = scope.where(category: params[:category])
    end

    # Apply read filter if specified
    if params[:read].present?
      scope = scope.where(read: params[:read] == "true")
    end

    # Delete all notifications in scope
    scope.destroy_all

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  private

  # Set notification from ID parameter
  def set_notification
    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Notification not found"
    redirect_to notifications_path
  end
end

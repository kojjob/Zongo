class Admin::ContactSubmissionsController < ApplicationController
  # Include Pagy for pagination if available
  begin
    require "pagy"
    include Pagy::Backend
  rescue LoadError
    # Fallback method if Pagy is not available
    def pagy(collection, options = {})
      items = options[:items] || 20
      page = (params[:page] || 1).to_i

      total = collection.count
      offset = (page - 1) * items
      subset = collection.offset(offset).limit(items)

      # Simple OpenStruct to mimic Pagy behavior
      pagy_obj = OpenStruct.new(
        count: total,
        page: page,
        items: items,
        pages: (total.to_f / items).ceil,
        prev: page > 1 ? page - 1 : nil,
        next: page * items < total ? page + 1 : nil,
        offset: offset,
        from: offset + 1,
        to: [ offset + items, total ].min,
        total_count: total
      )

      return pagy_obj, subset
    end
  end

  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_contact_submission, only: [ :show, :destroy, :mark_as_read ]
  layout "admin"

  def index
    @contact_submissions = ContactSubmission.order(created_at: :desc)

    # Filter by read status if provided
    if params[:status] == "unread"
      @contact_submissions = @contact_submissions.unread
    elsif params[:status] == "read"
      @contact_submissions = @contact_submissions.where(read: true)
    end

    # Paginate results
    @pagy, @contact_submissions = pagy(@contact_submissions, items: 10)

    # Count for sidebar
    @unread_contact_submissions = ContactSubmission.unread.count
  end

  def show
    # Count for sidebar
    @unread_contact_submissions = ContactSubmission.unread.count
  end

  def mark_as_read
    if @contact_submission.update(read: true, read_at: Time.current)
      redirect_to admin_contact_submission_path(@contact_submission), notice: "Message marked as read."
    else
      redirect_to admin_contact_submission_path(@contact_submission), alert: "Failed to mark message as read."
    end
  end

  def destroy
    @contact_submission.destroy
    redirect_to admin_contact_submissions_path, notice: "Message deleted successfully."
  end

  private

  def set_contact_submission
    @contact_submission = ContactSubmission.find(params[:id])
  end

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "You don't have permission to access this page."
    end
  end
end

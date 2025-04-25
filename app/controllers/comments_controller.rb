class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_comment, only: [ :destroy ]

  # POST /events/:event_id/comments
  def create
    result = CommentService.new(@event, current_user).create_comment(comment_params[:content], comment_params[:parent_id])

    if result.success?
      redirect_to event_path(@event, anchor: "comments"), notice: "Comment added successfully!"
    else
      redirect_to event_path(@event, anchor: "comments"), alert: result.error
    end
  end

  # DELETE /events/:event_id/comments/:id
  def destroy
    result = CommentService.new(@event, current_user).delete_comment(@comment.id)

    if result.success?
      redirect_to event_path(@event, anchor: "comments"), notice: "Comment deleted successfully."
    else
      redirect_to event_path(@event, anchor: "comments"), alert: result.error
    end
  end

  private

  def set_event
    # Try to find by slug first, then by ID
    @event = Event.find_by(slug: params[:event_id]) || Event.find_by(id: params[:event_id])

    unless @event
      flash[:alert] = "Event not found"
      redirect_to events_path
    end
  end

  def set_comment
    @comment = @event.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end
end

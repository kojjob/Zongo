class CommentService
  def initialize(event, user)
    @event = event
    @user = user
  end

  def create_comment(content, parent_id = nil)
    return Result.failure("You must be logged in to comment") unless @user

    comment = @event.comments.build(
      user: @user,
      content: content,
      parent_id: parent_id
    )

    if comment.save
      # Notify relevant people about the comment
      # notify_about_comment(comment)
      Result.success(comment)
    else
      Result.failure(comment.errors.full_messages.join(", "))
    end
  end

  def delete_comment(comment_id)
    return Result.failure("You must be logged in to delete comments") unless @user

    comment = @event.comments.find_by(id: comment_id)
    return Result.failure("Comment not found") unless comment

    # Only allow comment author or event organizer to delete
    unless @user == comment.user || @user == @event.organizer
      return Result.failure("You don't have permission to delete this comment")
    end

    if comment.destroy
      Result.success(nil)
    else
      Result.failure("Failed to delete comment")
    end
  end

  private

  def notify_about_comment(comment)
    # Notify event organizer about new comment
    # NotificationService.new(@event.organizer).notify_new_comment(@event, comment) unless @user == @event.organizer

    # If this is a reply, notify parent comment author
    # if comment.parent_id.present?
    #   parent_author = comment.parent.user
    #   NotificationService.new(parent_author).notify_comment_reply(comment) unless parent_author == @user
    # end
  end
end

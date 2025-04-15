class EventAttendanceService
  def initialize(event, user)
    @event = event
    @user = user
  end

  def attend
    return Result.failure("You must be logged in to attend events") unless @user
    return Result.failure("Event is sold out") if @event.sold_out?
    return Result.failure("Already attending") if already_attending?

    attendance = @event.attendances.build(user: @user)

    if attendance.save
      # We would normally send emails here and trigger notifications
      # EventMailer.attendance_confirmation(@event, @user).deliver_later
      # NotificationService.new(@event.organizer).notify_new_attendee(@event, @user)
      Result.success(attendance)
    else
      Result.failure(attendance.errors.full_messages.join(", "))
    end
  end

  def cancel
    return Result.failure("You must be logged in to manage attendance") unless @user

    attendance = @event.attendances.find_by(user: @user)
    return Result.failure("Not attending") unless attendance

    if attendance.destroy
      Result.success(nil)
    else
      Result.failure("Could not cancel attendance")
    end
  end

  private

  def already_attending?
    @event.attendances.exists?(user_id: @user.id)
  end
end

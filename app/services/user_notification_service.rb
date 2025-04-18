class UserNotificationService
  def initialize(user = nil)
    @user = user
  end

  def notify_loan_approved(loan)
    user = loan.user

    # Create notification record
    create_notification(
      user: user,
      title: "Loan Approved",
      body: "Your loan application for #{loan.amount} GHS has been approved.",
      category: "loan",
      action_url: "/loans/#{loan.id}"
    )

    # Send email notification if user has email notifications enabled
    if user.user_settings&.email_notifications
      # In a real application, this would send an actual email
      # LoanMailer.loan_approved(loan).deliver_later
      Rails.logger.info "Email notification sent to #{user.email} for loan approval"
    end

    # Send SMS notification if user has SMS notifications enabled
    if user.user_settings&.sms_notifications
      # In a real application, this would send an actual SMS
      # SmsService.send_message(user.phone, "Your loan application for #{loan.amount} GHS has been approved.")
      Rails.logger.info "SMS notification sent to #{user.phone} for loan approval"
    end
  end

  def notify_loan_rejected(loan)
    user = loan.user

    # Create notification record
    create_notification(
      user: user,
      title: "Loan Application Rejected",
      body: "Your loan application has been rejected. Reason: #{loan.rejection_reason}",
      category: "loan",
      action_url: "/loans/#{loan.id}"
    )

    # Send email notification if user has email notifications enabled
    if user.user_settings&.email_notifications
      # LoanMailer.loan_rejected(loan).deliver_later
      Rails.logger.info "Email notification sent to #{user.email} for loan rejection"
    end
  end

  def notify_loan_disbursed(loan)
    user = loan.user

    # Create notification record
    create_notification(
      user: user,
      title: "Loan Disbursed",
      body: "Your loan of #{loan.amount} GHS has been disbursed to your wallet.",
      category: "loan",
      action_url: "/loans/#{loan.id}"
    )

    # Send email notification if user has email notifications enabled
    if user.user_settings&.email_notifications
      # LoanMailer.loan_disbursed(loan).deliver_later
      Rails.logger.info "Email notification sent to #{user.email} for loan disbursement"
    end

    # Send SMS notification if user has SMS notifications enabled
    if user.user_settings&.sms_notifications
      # SmsService.send_message(user.phone, "Your loan of #{loan.amount} GHS has been disbursed to your wallet.")
      Rails.logger.info "SMS notification sent to #{user.phone} for loan disbursement"
    end
  end

  def notify_loan_due_soon(loan, days_remaining)
    user = loan.user

    # Create notification record
    create_notification(
      user: user,
      title: "Loan Payment Due Soon",
      body: "Your loan payment of #{loan.amount_due} GHS is due in #{days_remaining} days.",
      category: "loan",
      action_url: "/loans/#{loan.id}"
    )

    # Send email notification if user has email notifications enabled
    if user.user_settings&.email_notifications
      # LoanMailer.loan_due_soon(loan, days_remaining).deliver_later
      Rails.logger.info "Email notification sent to #{user.email} for loan due soon"
    end

    # Send SMS notification if user has SMS notifications enabled
    if user.user_settings&.sms_notifications
      # SmsService.send_message(user.phone, "Your loan payment of #{loan.amount_due} GHS is due in #{days_remaining} days.")
      Rails.logger.info "SMS notification sent to #{user.phone} for loan due soon"
    end
  end

  def notify_loan_overdue(loan, days_overdue)
    user = loan.user

    # Create notification record
    create_notification(
      user: user,
      title: "Loan Payment Overdue",
      body: "Your loan payment of #{loan.amount_due} GHS is overdue by #{days_overdue} days.",
      category: "loan",
      action_url: "/loans/#{loan.id}",
      severity: "high"
    )

    # Send email notification if user has email notifications enabled
    if user.user_settings&.email_notifications
      # LoanMailer.loan_overdue(loan, days_overdue).deliver_later
      Rails.logger.info "Email notification sent to #{user.email} for loan overdue"
    end

    # Send SMS notification if user has SMS notifications enabled
    if user.user_settings&.sms_notifications
      # SmsService.send_message(user.phone, "Your loan payment of #{loan.amount_due} GHS is overdue by #{days_overdue} days.")
      Rails.logger.info "SMS notification sent to #{user.phone} for loan overdue"
    end
  end

  private

  def create_notification(user:, title:, body:, category:, action_url:, severity: "normal")
    # Check if Notification model exists
    if defined?(Notification)
      Notification.create(
        user: user,
        title: title,
        body: body,
        category: category,
        action_url: action_url,
        severity: severity,
        read: false
      )
    else
      # Log the notification if the model doesn't exist
      Rails.logger.info "Notification for #{user.email}: #{title} - #{body}"
    end
  end
end

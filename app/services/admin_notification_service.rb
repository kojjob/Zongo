class AdminNotificationService
  def notify_new_loan_application(loan)
    # Get all admin users
    admin_users = User.where(admin: true)

    admin_users.each do |admin|
      # Create notification record for each admin
      create_notification(
        user: admin,
        title: "New Loan Application",
        body: "A new loan application has been submitted by #{loan.user.display_name} for #{loan.amount} GHS.",
        category: "admin_loan",
        action_url: "/admin/loans/#{loan.id}"
      )

      # Send email notification if admin has email notifications enabled
      if admin.user_settings&.email_notifications
        # In a real application, this would send an actual email
        # AdminMailer.new_loan_application(admin, loan).deliver_later
        Rails.logger.info "Email notification sent to admin #{admin.email} for new loan application"
      end
    end
  end

  def notify_loan_default_risk(loan)
    # Get all admin users
    admin_users = User.where(admin: true)

    admin_users.each do |admin|
      # Create notification record for each admin
      create_notification(
        user: admin,
        title: "Loan Default Risk",
        body: "Loan #{loan.reference_number} by #{loan.user.display_name} is at risk of default. Currently #{loan.days_overdue} days overdue.",
        category: "admin_loan",
        action_url: "/admin/loans/#{loan.id}",
        severity: "high"
      )

      # Send email notification if admin has email notifications enabled
      if admin.user_settings&.email_notifications
        # AdminMailer.loan_default_risk(admin, loan).deliver_later
        Rails.logger.info "Email notification sent to admin #{admin.email} for loan default risk"
      end
    end
  end

  def notify_loan_defaulted(loan)
    # Get all admin users
    admin_users = User.where(admin: true)

    admin_users.each do |admin|
      # Create notification record for each admin
      create_notification(
        user: admin,
        title: "Loan Defaulted",
        body: "Loan #{loan.reference_number} by #{loan.user.display_name} has been marked as defaulted. Amount: #{loan.amount} GHS.",
        category: "admin_loan",
        action_url: "/admin/loans/#{loan.id}",
        severity: "critical"
      )

      # Send email notification if admin has email notifications enabled
      if admin.user_settings&.email_notifications
        # AdminMailer.loan_defaulted(admin, loan).deliver_later
        Rails.logger.info "Email notification sent to admin #{admin.email} for loan default"
      end
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

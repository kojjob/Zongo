class SecurityController < ApplicationController
  before_action :authenticate_user!

  # Display security dashboard with alerts and activity
  def dashboard
    @security_logs = current_user.security_logs.recent.limit(10)
    @recent_activities = Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?",
                                        current_user.wallet.id, current_user.wallet.id)
                                  .order(created_at: :desc)
                                  .limit(5)
  end

  # Display security settings
  def settings
    @user = current_user
  end

  # Display security education materials
  def education
    # Determine which educational content to show based on user's security status
    @show_alert_education = params[:topic] == "alerts" ||
                           has_recent_security_alerts?(current_user)

    @show_transaction_education = params[:topic] == "transactions" ||
                                 has_recent_transaction_security_events?(current_user)

    # Always show general security tips
    @show_security_tips = true
  end

  # Display security activity log
  def activity
    @security_logs = current_user.security_logs
                               .order(created_at: :desc)
                               .page(params[:page])
                               .per(20)
  end

  private

  # Check if user has received security alerts recently
  def has_recent_security_alerts?(user)
    user.notifications.security
                     .where(severity: [ :warning, :critical ])
                     .where("created_at > ?", 7.days.ago)
                     .exists?
  end

  # Check if user has had recent transaction security events
  def has_recent_transaction_security_events?(user)
    SecurityLog.where(user_id: user.id)
              .where(event_type: [ :transaction_check, :transaction_blocked ])
              .where("created_at > ?", 7.days.ago)
              .exists?
  end
end

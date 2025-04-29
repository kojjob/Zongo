require 'rufus-scheduler'

# Do not schedule jobs when running tests or in the Rails console
if defined?(Rails::Server) && !Rails.env.test?
  scheduler = Rufus::Scheduler.singleton

  # Schedule loan reminder job to run daily at 8:00 AM
  scheduler.cron '0 8 * * *' do
    Rails.logger.info "Running LoanReminderJob at #{Time.current}"
    LoanReminderJob.perform_later
  end

  # Schedule loan status update job to run daily at midnight
  scheduler.cron '0 0 * * *' do
    Rails.logger.info "Running LoanStatusUpdateJob at #{Time.current}"
    LoanStatusUpdateJob.perform_later
  end

  # Schedule credit score update job to run daily at 2:00 AM
  scheduler.cron '0 2 * * *' do
    Rails.logger.info "Running CreditScoreUpdateJob at #{Time.current}"
    CreditScoreUpdateJob.perform_later
  end
end

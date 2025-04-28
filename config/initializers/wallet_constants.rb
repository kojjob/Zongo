# Wallet system configuration constants
# These values can be overridden in environment-specific configuration

# Default wallet settings
Rails.application.config.x.wallet = {
  # Default currency for new wallets
  default_currency: ENV.fetch('DEFAULT_WALLET_CURRENCY', 'GHS'),
  
  # Default daily transaction limit
  default_daily_limit: ENV.fetch('DEFAULT_WALLET_DAILY_LIMIT', 1000).to_f,
  
  # Default initial balance for new wallets
  default_initial_balance: ENV.fetch('DEFAULT_WALLET_INITIAL_BALANCE', 0).to_f,
  
  # Wallet ID prefix (used when generating new wallet IDs)
  wallet_id_prefix: ENV.fetch('WALLET_ID_PREFIX', 'W'),
  
  # Length of the random part of wallet IDs
  wallet_id_random_length: ENV.fetch('WALLET_ID_RANDOM_LENGTH', 12).to_i,
  
  # System wallet ID for bill payments and other system operations
  system_wallet_id: ENV.fetch('SYSTEM_WALLET_ID', 'SYSTEM'),
  
  # System user email (used for system wallet)
  system_user_email: ENV.fetch('SYSTEM_USER_EMAIL', 'system@superghana.com'),
  
  # System wallet daily limit (higher than regular wallets)
  system_wallet_daily_limit: ENV.fetch('SYSTEM_WALLET_DAILY_LIMIT', 1000000).to_f,
  
  # Number of recent transactions to show on dashboard
  dashboard_recent_transactions_count: ENV.fetch('DASHBOARD_RECENT_TRANSACTIONS', 5).to_i,
  
  # Number of recent beneficiaries to show on dashboard
  dashboard_recent_beneficiaries_count: ENV.fetch('DASHBOARD_RECENT_BENEFICIARIES', 5).to_i,
  
  # Number of days to use for savings/spending calculations
  dashboard_financial_period_days: ENV.fetch('DASHBOARD_FINANCIAL_PERIOD_DAYS', 30).to_i,
  
  # Default number of days for transaction history
  default_transaction_history_days: ENV.fetch('DEFAULT_TRANSACTION_HISTORY_DAYS', 90).to_i,
  
  # Default items per page for pagination
  pagination_items_per_page: ENV.fetch('PAGINATION_ITEMS_PER_PAGE', 20).to_i,
  
  # Number of recent recipients to show on send money page
  send_money_recent_recipients_count: ENV.fetch('SEND_MONEY_RECENT_RECIPIENTS', 10).to_i
}

# Temporary placeholder values (these should be replaced with actual calculations in production)
Rails.application.config.x.wallet[:placeholder_savings_change] = ENV.fetch('PLACEHOLDER_SAVINGS_CHANGE', 16.8).to_f
Rails.application.config.x.wallet[:placeholder_spending_change] = ENV.fetch('PLACEHOLDER_SPENDING_CHANGE', -16.8).to_f

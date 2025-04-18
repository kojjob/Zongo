Rails.application.routes.draw do
  # Active Storage routes
  # This is needed since we're using Rails 8.0
  direct :rails_blob do |blob, options = {}|
    route_for(:rails_service_blob, blob.signed_id, blob.filename, options)
  end
  direct :rails_representation do |representation, options = {}|
    route_for(:rails_service_blob_representation, representation.blob.signed_id, representation.variation_key, representation.blob.filename, options)
  end

  # Devise routes with proper configuration
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords"
  }, sign_out_via: [ :get, :delete ], path_names: {
    sign_in: "sign_in",
    sign_out: "sign_out",
    password: "password",
    confirmation: "confirmation",
    registration: "sign_up",
    sign_up: ""
  }

  # Custom password reset pages - wrapped in devise_scope to ensure proper mapping
  devise_scope :user do
    get "users/password/reset_success", to: "users/passwords#reset_success", as: "password_reset_success"
    get "users/password/instructions_sent", to: "users/passwords#instructions_sent", as: "password_instructions_sent"
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Theme testing route
  # get '/theme-test', to: 'pages#theme_test'
  get "/theme-test", to: "pages#theme_test", layout: "application"

  # Test controller routes
  get "/test", to: "test#index"
  get "/test/theme", to: "test#theme_test"
  get "/test/dropdown", to: "test#dropdown_test"
  get "/test/main", to: "test#main_app_test"

  # Event routes
  resources :events do
    member do
      post "attend"
      delete "cancel_attendance"
      post "toggle_favorite"
      get "calendar", to: "events#download_ics", as: "calendar"
    end
    collection do
      get "upcoming"
      get "past"
      get "featured"
      get "my_events"
    end
    resources :event_comments, only: [ :create, :destroy ]
    resources :event_media, only: [ :create, :destroy, :index ]
    resource :analytics, only: [ :show ], controller: "event_analytics"
  end

  # Event-related resources
  resources :venues
  resources :categories
  resources :attendances
  resources :ticket_types
  resources :event_tickets
  resources :event_comments
  resources :event_favorites
  resources :event_media do
    member do
      post :set_as_featured
    end
  end
  resources :event_categories

  # New Wallet routes
  get "wallet", to: "wallet#dashboard", as: "wallet"
  get "wallet/send", to: "wallet#send_money", as: "send_money"
  post "wallet/send", to: "wallet#process_send_money"
  get "wallet/receive", to: "wallet#receive_money", as: "receive_money"
  get "wallet/pay_bill/:type", to: "wallet#pay_bill", as: "pay_bill"
  post "wallet/pay_bill", to: "wallet#process_bill_payment", as: "process_bill_payment"
  get "wallet/bills", to: "wallet#bills", as: "wallet_bills"
  # Redirect /bills to /wallet/bills for convenience
  get "bills", to: redirect("/wallet/bills")
  # Payment link route
  get "pay/:wallet_id", to: "wallet#payment_page", as: "payment_page"
  get "wallet/beneficiaries", to: "wallet#beneficiaries", as: "beneficiaries"
  get "wallet/beneficiaries/new", to: "wallet#new_beneficiary", as: "new_beneficiary"
  post "wallet/beneficiaries", to: "wallet#create_beneficiary"
  get "wallet/transactions", to: "wallet#transactions", as: "transactions"

  # Transfers routes
  resources :transfers, only: [ :new, :create ]

  # Legacy Wallet routes
  resource :wallet, only: [ :show, :edit, :update ], controller: "wallets" do
    get "new_transaction/:type", to: "wallets#new_transaction", as: "new_transaction"
    post "deposit", to: "wallets#deposit"
    post "withdraw", to: "wallets#withdraw"
    post "transfer", to: "wallets#transfer"
    get "transactions", to: "wallets#transactions"
    get "transaction/:id", to: "wallets#transaction_details", as: "transaction"
    get "refresh_balance", to: "wallets#refresh_balance"
    get "recent_transactions", to: "wallets#recent_transactions"
  end

  # Transaction routes
  resources :transactions, only: [ :index, :show, :new, :create ] do
    member do
      post :process_transaction
      post :reverse
    end
  end

  # Legacy transaction route for backward compatibility
  get "transaction/:id", to: "transactions#show"

  # Dashboard routes
  get "dashboard", to: "dashboard#index"
  get "dashboard/refresh_balance", to: "dashboard#refresh_balance"
  get "dashboard/refresh_transactions", to: "dashboard#refresh_transactions"

  # Scheduled Transactions routes
  resources :scheduled_transactions do
    member do
      post "pause"
      post "resume"
      post "execute"
    end
  end

  # Statement routes
  get "/statements/new", to: "statements#new", as: "new_statement"
  get "/statements/generate", to: "statements#generate", as: "generate_statement"

  # Loan routes
  resources :loans do
    collection do
      get :eligibility
      get :types
    end

    member do
      post :repay
      get :schedule
      get :details
    end
  end

  # Payment methods routes
  resources :payment_methods do
    post "set_default", on: :member
    post "verify", on: :member
  end

  # Settings routes
  get "user_settings", to: "user_settings#index"
  get "user_settings/profile", to: "user_settings#profile"
  get "user_settings/security", to: "user_settings#security"
  get "user_settings/notifications", to: "user_settings#notifications"
  get "user_settings/appearance", to: "user_settings#appearance"
  get "user_settings/payment", to: "user_settings#payment"
  get "user_settings/support", to: "user_settings#support"

  # Shortcut routes for better UX
  get "profile", to: "user_settings#profile", as: "profile"
  get "settings", to: "user_settings#index", as: "settings"
  get "support", to: "user_settings#support", as: "support"

  # user_Settings update routes
  patch "user_settings/update_profile", to: "user_settings#update_profile", as: "update_profile"
  patch "profile/update", to: "user_settings#update_profile" # Shortcut for profile updates
  patch "user_settings/update_security", to: "user_settings#update_security"
  patch "user_settings/update_notifications", to: "user_settings#update_notifications"
  patch "user_settings/update_appearance", to: "user_settings#update_appearance"
  post "user_settings/toggle_setting", to: "user_settings#toggle_setting"

  # Avatar management
  delete "user_settings/remove_avatar", to: "user_settings#remove_avatar", as: "remove_avatar"
  delete "profile/remove_avatar", to: "user_settings#remove_avatar" # Shortcut for avatar removal

  # Security Settings routes
  get "security_settings", to: "security_settings#index"
  post "security_settings/set_pin", to: "security_settings#set_pin", as: "set_pin"
  delete "security_settings/remove_pin", to: "security_settings#remove_pin", as: "remove_pin"
  get "security_settings/activity_logs", to: "security_settings#activity_logs", as: "security_activity_logs"
  post "security_settings/lock_account", to: "security_settings#lock_account", as: "lock_account"
  patch "security_settings/update_preferences", to: "security_settings#update_preferences", as: "update_security_preferences"

  # Diagnostic route for avatar issues
  get "/check_avatar", to: "pages#check_avatar"
  get "about", to: "pages#about"

  namespace :admin do
    # Admin Dashboard routes
    get "dashboard", to: "dashboard#index", as: "dashboard"
    get "dashboard/users", to: "dashboard#users", as: "users_dashboard"
    get "dashboard/transactions", to: "dashboard#transactions", as: "transactions"
    get "dashboard/scheduled_transactions", to: "dashboard#scheduled_transactions", as: "scheduled_transactions"
    get "dashboard/events", to: "dashboard#events", as: "events"
    get "dashboard/system", to: "dashboard#system", as: "system"
    get "dashboard/loans", to: "dashboard#loans", as: "loans"

    # Notifications
    resources :notifications, only: [:index]

    # User management
    resources :users do
      member do
        post :suspend
        post :activate
        post :promote
        post :demote
      end
    end

    # Loan management
    resources :loans, only: [ :index, :show ] do
      member do
        post :approve
        post :reject
        post :disburse
      end
    end

    # Product management
    resources :products do
      member do
        post :suspend
        post :activate
      end
    end

    # Contact submissions
    resources :contact_submissions do
      member do
        patch :mark_as_read
      end
    end
  end

  get "contact", to: "contact#index"
  post "contact/submit", to: "contact#submit"

  # Flash message management
  post "clear_flash", to: "flash#clear", as: :clear_flash

  # Defines the root path route ("/")
  root "pages#home"
end

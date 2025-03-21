Rails.application.routes.draw do
  # Active Storage routes
  # This is needed since we're using Rails 8.0
  direct :rails_blob do |blob, options={}|
    route_for(:rails_service_blob, blob.signed_id, blob.filename, options)
  end
  direct :rails_representation do |representation, options={}|
    route_for(:rails_service_blob_representation, representation.blob.signed_id, representation.variation_key, representation.blob.filename, options)
  end
  devise_for :users, sign_out_via: [ :get, :delete ]
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Theme testing route
  # get '/theme-test', to: 'pages#theme_test'
  get "/theme-test", to: "pages#theme_test", layout: "application"
  
  # Test controller routes
  get '/test', to: 'test#index'
  get '/test/theme', to: 'test#theme_test'
  get '/test/dropdown', to: 'test#dropdown_test'
  get '/test/main', to: 'test#main_app_test'

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Wallet routes
  resource :wallet, only: [:show, :edit, :update] do
    get 'new_transaction/:type', to: 'wallets#new_transaction', as: 'new_transaction'
    post 'deposit', to: 'wallets#deposit'
    post 'withdraw', to: 'wallets#withdraw'
    post 'transfer', to: 'wallets#transfer'
    get 'transactions', to: 'wallets#transactions'
    get 'transactions/:id', to: 'wallets#transaction_details', as: 'transaction'
    get 'refresh_balance', to: 'wallets#refresh_balance'
    get 'recent_transactions', to: 'wallets#recent_transactions'
  end

  # Dashboard routes
  get 'dashboard', to: 'dashboard#index'
  get 'dashboard/refresh_balance', to: 'dashboard#refresh_balance'
  get 'dashboard/refresh_transactions', to: 'dashboard#refresh_transactions'

  # Scheduled Transactions routes
  resources :scheduled_transactions do
    member do
      post 'pause'
      post 'resume'
      post 'execute'
    end
  end

  # Statement routes
  get '/statements/new', to: 'statements#new', as: 'new_statement'
  get '/statements/generate', to: 'statements#generate', as: 'generate_statement'

  # Payment methods routes
  resources :payment_methods do
    post 'set_default', on: :member
    post 'verify', on: :member
  end

  # Settings routes
  get 'user_settings', to: 'user_settings#index'
  get 'user_settings/profile', to: 'user_settings#profile'
  get 'user_settings/security', to: 'user_settings#security'
  get 'user_settings/notifications', to: 'user_settings#notifications'
  get 'user_settings/appearance', to: 'user_settings#appearance'
  get 'user_settings/payment', to: 'user_settings#payment'
  get 'user_settings/support', to: 'user_settings#support'

  # user_Settings update routes
  patch 'user_settings/update_profile', to: 'user_settings#update_profile'
  patch 'user_settings/update_security', to: 'user_settings#update_security'
  patch 'user_settings/update_notifications', to: 'user_settings#update_notifications'
  patch 'user_settings/update_appearance', to: 'user_settings#update_appearance'
  post 'user_settings/toggle_setting', to: 'user_settings#toggle_setting'


  # Avatar management
  delete 'user_settings/remove_avatar', to: 'user_settings#remove_avatar', as: 'remove_avatar'
  
  # Diagnostic route for avatar issues
  get '/check_avatar', to: 'pages#check_avatar'
  get 'about', to: 'pages#about'

  namespace :admin do
    resources :contact_submissions do
      member do
        patch :mark_as_read
      end
    end
  end

  get 'contact', to: 'contact#index'
  post 'contact/submit', to: 'contact#submit'
  
  # Defines the root path route ("/")
  root "pages#home"
end

require 'sidekiq/web'
require 'sidekiq/cron/web'

class AdminConstraint
  def matches?(request)
    user_id = request.cookie_jar.encrypted[:user_id]
    user_id.present? && User.find_by(id: user_id)&.admin?
  end
end

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new

  namespace :admin do
    get 'notifications', to: 'notifications#index', as: :notifications
    patch 'notifications/update_config', to: 'notifications#update_config', as: :notifications_update_config
    patch 'notifications/update_user/:id', to: 'notifications#update_user', as: :notifications_update_user
  end

  resources :locations
  resources :recipe_sources
  resources :recipes
  resources :recipe_batches do
    collection do
      get :for_recipe
    end
  end
  resources :tanks do
    resources :water_tests
  end
  resources :sensor_types
  resources :sensors
  resources :zones
  resource :session
  resources :registrations
  resource :password
  resource :password_reset

  post 'guest', to: 'guests#create'
  resource :guest_conversion, only: [:new, :create]
  post 'auth/google/callback', to: 'google_auth#callback'

  resources :users

  resources :saved_searches, only: [:create, :destroy]

  get 'plants/archive', to: 'plants#archive'
  get 'plants/import', to: 'plants#import'
  post 'plants/import', to: 'plants#process_file'
  resources :plants do
    get 'water'
    post 'quick_water'
    resources :log_entries
    resources :soil_moisture_readings
    collection do
      get :suggest_graphic
    end
    member do
      post 'share', to: 'plants#create_share', as: 'create_share'
      delete 'share', to: 'plants#revoke_share', as: 'revoke_share'
      post 'regenerate_share', to: 'plants#regenerate_share', as: 'regenerate_share'
      post 'view_share', to: 'plants#create_view_share', as: 'create_view_share'
      delete 'view_share', to: 'plants#revoke_view_share', as: 'revoke_view_share'
      post 'regenerate_view_share', to: 'plants#regenerate_view_share', as: 'regenerate_view_share'
    end
  end

  get 'waterings/import', to: 'waterings#import'
  post 'waterings/import', to: 'waterings#process_file'
  resources :waterings

  root "plants#index"

  get 'weather', to: 'weather#index'
  post 'weather/lookup', to: 'weather#lookup', as: 'weather_lookup'
  resources :weather_locations, only: [:create, :update, :destroy] do
    member do
      patch :set_primary
    end
  end

  get 'settings', to: 'settings#index'
  patch 'settings', to: 'settings#update'
  delete 'settings', to: 'settings#destroy'
  post 'settings/send_test_email', to: 'settings#send_test_email', as: 'send_test_email'
  post 'settings/send_test_push', to: 'settings#send_test_push', as: 'send_test_push'
  patch 'settings/toggle_notification', to: 'settings#toggle_notification', as: 'toggle_notification'
  patch 'settings/disable_all_notifications', to: 'settings#disable_all_notifications', as: 'disable_all_notifications'
  resources :push_subscriptions, only: [:create, :destroy] do
    member do
      patch :toggle
    end
  end
  get 'en', to: 'settings#english'
  get 'es', to: 'settings#spanish'

  resources :projects do
    post 'add_collaborator'
    put 'remove_collaborator/:user_id', to: 'projects#remove_collaborator', as: 'remove_collaborator'
  end

  get 'sensor_readings/import', to: 'sensor_readings#import'
  post 'sensor_readings/import', to: 'sensor_readings#process_file'
  get 'transmit', to: 'sensor_readings#transmit', as: 'transmit'
  get 'sensor_readings', to: 'sensor_readings#readings', as: 'sensor_readings'

  get 'shared/plants/:token', to: 'shared_plants#show', as: 'shared_plant'
  post 'shared/plants/:token/waterings', to: 'shared_plants#create_watering', as: 'shared_plant_waterings'

  get '/.well-known/assetlinks.json', to: 'static#assetlinks'

  match '/404' => 'errors#not_found', :via => :all
  match '/422' => 'errors#unprocessable_entity', :via => :all
  match '/500' => 'errors#internal_server_error', :via => :all
end

Rails.application.routes.draw do
  resources :locations
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

  get 'plants/archive', to: 'plants#archive'
  get 'plants/import', to: 'plants#import'
  post 'plants/import', to: 'plants#process_file'
  resources :plants do
    get 'water'
    resources :log_entries
    collection do
      get :suggest_graphic
    end
    member do
      post 'share', to: 'plants#create_share', as: 'create_share'
      delete 'share', to: 'plants#revoke_share', as: 'revoke_share'
      post 'regenerate_share', to: 'plants#regenerate_share', as: 'regenerate_share'
    end
  end

  get 'waterings/import', to: 'waterings#import'
  post 'waterings/import', to: 'waterings#process_file'
  resources :waterings

  root "plants#index"

  get 'settings', to: 'settings#index'
  patch 'settings', to: 'settings#update'
  delete 'settings', to: 'settings#destroy'
  post 'settings/send_test_email', to: 'settings#send_test_email', as: 'send_test_email'
  post 'settings/send_test_push', to: 'settings#send_test_push', as: 'send_test_push'
  resources :push_subscriptions, only: [:create, :destroy]
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

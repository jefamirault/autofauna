Rails.application.routes.draw do
  resource :session
  resources :registrations
  resource :password
  resource :password_reset

  get 'plants/import', to: 'plants#import'
  post 'plants/import', to: 'plants#process_file'
  resources :plants do
    get 'water'
  end

  resources :waterings

  root "plants#index"

  get 'settings', to: 'settings#index'
end

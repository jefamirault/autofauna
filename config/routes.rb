Rails.application.routes.draw do
  resource :session
  resources :registrations
  resource :password
  resource :password_reset

  resources :users

  get 'plants/import', to: 'plants#import'
  post 'plants/import', to: 'plants#process_file'
  resources :plants do
    get 'water'
  end

  resources :waterings

  root "projects#index"

  get 'settings', to: 'settings#index'

  resources :projects do
    post 'add_collaborator'
    put 'remove_collaborator/:user_id', to: 'projects#remove_collaborator', as: 'remove_collaborator'
  end
end

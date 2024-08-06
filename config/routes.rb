Rails.application.routes.draw do
  get 'sessions/new'
  post 'sessions/create'
  get 'sessions/destroy'

  resources :waterings


  get 'plants/import', to: 'plants#import'
  post 'plants/import', to: 'plants#process_file'
  resources :plants do
    get 'water'
  end

  root "plants#index"
end

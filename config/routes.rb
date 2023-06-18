Rails.application.routes.draw do
  resources :waterings
  resources :plants do
    get 'water'
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "plants#index"
end

# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "posts/create"
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      # Change this line to handle the activation route
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
      resources :posts, only: [:create]

      match 'signup', to: 'application#options', via: :options

    end
  end
end
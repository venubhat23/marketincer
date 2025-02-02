# config/routes.rb
Rails.application.routes.draw do
  #match '*path', to: 'application#options', via: :options
  namespace :api do
    namespace :v1 do
      get "posts/create"
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      # Change this line to handle the activation route
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
      resources :posts, only: [:create]
    end
  end
end
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      # Change this line to handle the activation route
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
    end
  end
end
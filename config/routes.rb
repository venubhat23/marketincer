# config/routes.rb
Rails.application.routes.draw do
  #match '*path', to: 'application#options', via: :options
  namespace :api do
    namespace :v1 do
      # Existing authentication routes
      get "posts/create"
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
      
      # Social media integration routes
      resources :social_accounts, only: [] do
        collection do
          get :get_pages
        end
      end
      
      resources :social_pages, only: [] do
        collection do
          post :connect
          get :connected_pages
        end
      end
      
      # Combined posts routes
      resources :posts, only: [:create]
    end
  end
end
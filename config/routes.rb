Rails.application.routes.draw do
  get "/health", to: "health#show"

  namespace :api do
    namespace :v1 do

      get 'influencer/analytics', to: 'influencer_analytics#show'

      # Authentication routes
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
      post '/linkedin/connect', to: 'linkedin#connect'  # New connect endpoint

      # User profile update route
      put 'user/update_profile', to: 'users#update_profile'

      # Social media integration routes
      resources :social_accounts, only: [] do
        collection do
          post :get_pages
        end
      end

      resources :social_pages, only: [] do
        collection do
          post :connect
          get :connected_pages
          delete :dis_connect
        end
      end

      # Posts routes
      resources :posts, only: [:create, :update, :destroy] do
        collection do
          post :schedule
          get :search
        end
      end

      post '/linkedin/exchange-token', to: 'linkedin#exchange_token'
      get '/linkedin/profile', to: 'linkedin#get_profile'

      resources :invoices do
        member do
          put :update_status
        end
        collection do
          get :dashboard
        end
      end

    resources :purchase_orders do
      collection do
        get 'dashboard'  # Dashboard API
      end
    end



    end
  end

  # Mount Sidekiq Web UI at `/sidekiq`
  mount Sidekiq::Web => '/sidekiq'
end

Rails.application.routes.draw do
  get "/health", to: "health#show"

  namespace :api do
    namespace :v1 do
      resources :contracts do
        collection do
          get :templates
          post :generate, to: 'contracts#generate_ai_contract'
          get :ai_status, to: 'contracts#ai_generation_status'
        end

        member do
          post :duplicate
          post :regenerate, to: 'contracts#regenerate_ai_contract'
        end
      end

      get 'influencer/analytics', to: 'influencer_analytics#show'
      get 'influencer_analytics/:page_id', to: 'influencer_analytics#show_single'

      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      get 'activate/:token', to: 'registrations#activate', as: 'activate'
      post '/linkedin/connect', to: 'linkedin#connect'
      put 'user/update_profile', to: 'users#update_profile'

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
          get 'dashboard'
        end
      end
    end
  end

  # ✅ Handle OPTIONS requests for CORS preflight
  match "*path", to: "application#preflight", via: [:options]

  # Mount Sidekiq Web UI at `/sidekiq`
  mount Sidekiq::Web => '/sidekiq'
end

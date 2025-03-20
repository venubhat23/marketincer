Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'signup', to: 'registrations#create'
      post 'login', to: 'sessions#create'
      get 'activate/:token', to: 'registrations#activate', as: 'activate'

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
      resources :posts, only: [:create] do
        collection do
          post :schedule  # New endpoint for scheduling posts
          get :search     # New endpoint for searching/filtering posts
        end
      end
    end
  end
end

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post '/login', to: 'authentication#login'
      post '/register', to: 'authentication#register'

      # Employee routes
      resources :employees do
        collection do
          get :salary_insights
        end
      end
    end
  end
end
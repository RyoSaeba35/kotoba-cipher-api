# config/routes.rb
Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      resources :puzzles, only: [:index, :show] do
        collection do
          get :daily
          get :bundle
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end

# config/routes.rb
Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      resources :puzzles, only: [ :index, :show ] do
        collection do
          get :daily
          get :bundle
          get "bundle/sync", to: "puzzles#sync"
        end
      end
      post "device_tokens", to: "device_tokens#upsert"

      namespace :jobs do
        post :daily_challenge, to: "jobs#daily_challenge"
        post :streak_reminder, to: "jobs#streak_reminder"
        post :re_engagement,   to: "jobs#re_engagement"
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end

# config/application.rb
require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module KotobaCipherApi
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    # REMOVED: config.api_only = true

    # Enable sessions for ActiveAdmin
    config.session_store :cookie_store, key: '_kotoba_cipher_session'
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, config.session_options

    # CORS for API endpoints
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
  end
end

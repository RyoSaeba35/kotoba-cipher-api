# app/controllers/api/v1/device_tokens_controller.rb
module Api
  module V1
    class DeviceTokensController < ApplicationController
      def upsert
        token = DeviceToken.find_or_initialize_by(token: params[:token])
        token.update!(
          platform:       params[:platform] || 'android',
          locale:         params[:locale]   || 'en',
          timezone:       params[:timezone] || 'Europe/Paris',
          last_active_at: Time.current,
        )
        render json: { status: 'ok' }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def complete_daily
        token = DeviceToken.find_by(token: params[:token])
        token&.update(last_daily_completed_at: Time.current)
        render json: { status: 'ok' }
      end
    end
  end
end

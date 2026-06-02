# app/controllers/api/v1/jobs_controller.rb
module Api
  module V1
    class JobsController < ApplicationController
      before_action :verify_cron_secret

      def daily_challenge
        NotificationJob.daily_challenge
        render json: { status: 'ok' }
      end

      def streak_reminder
        NotificationJob.streak_reminder
        render json: { status: 'ok' }
      end

      def re_engagement
        NotificationJob.re_engagement
        render json: { status: 'ok' }
      end

      private

      def verify_cron_secret
        unless request.headers['X-Cron-Secret'] == ENV['CRON_SECRET']
          render json: { error: 'unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end

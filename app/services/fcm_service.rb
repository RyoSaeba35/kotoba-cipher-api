# app/services/fcm_service.rb
require 'googleauth'
require 'net/http'
require 'json'

class FcmService
  FCM_URL = "https://fcm.googleapis.com/v1/projects/kotoba-ciphers/messages:send"
  SCOPE   = "https://www.googleapis.com/auth/firebase.messaging"

  def self.send_notification(token:, title:, body:, data: {})
    new.send_notification(token: token, title: title, body: body, data: data)
  end

  def send_notification(token:, title:, body:, data: {})
    access_token = get_access_token

    uri  = URI(FCM_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['Content-Type']  = 'application/json'
    request.body = {
      message: {
        token:        token,
        notification: { title: title, body: body },
        data:         data.transform_values(&:to_s),
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          }
        }
      }
    }.to_json

    response = http.request(request)

    if response.code == '200'
      Rails.logger.info "✅ FCM sent to #{token[0..20]}..."
      true
    else
      Rails.logger.error "❌ FCM failed: #{response.code} #{response.body}"
      # Remove invalid token
      if response.body.include?('UNREGISTERED') || response.body.include?('INVALID_ARGUMENT')
        DeviceToken.find_by(token: token)&.destroy
        Rails.logger.info "🗑️ Removed invalid token"
      end
      false
    end
  rescue => e
    Rails.logger.error "❌ FCM error: #{e.message}"
    false
  end

  private

  def get_access_token
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['FIREBASE_SERVICE_ACCOUNT']),
      scope:       SCOPE
    )
    credentials.fetch_access_token!['access_token']
  end
end

# app/jobs/notification_job.rb
class NotificationJob
  def self.daily_challenge
    Rails.logger.info "📬 Sending daily challenge notifications..."
    count = 0
    target_hour = 8

    DeviceToken.active.find_each do |device|
      user_time = Time.current.in_time_zone(device.timezone || 'Europe/Paris')
      next unless user_time.hour == target_hour

      title = device.locale == 'fr' ? 'Défi du jour disponible !' : 'Daily challenge is ready!'
      body  = device.locale == 'fr' ? 'Un nouveau cipher vous attend' : 'A new cipher is waiting for you'

      success = FcmService.send_notification(
        token: device.token,
        title: title,
        body:  body,
        data:  { type: 'daily_challenge' }
      )
      count += 1 if success
    end

    Rails.logger.info "✅ Daily challenge: sent #{count} notifications"
  end

  def self.streak_reminder
    Rails.logger.info "📬 Sending streak reminders..."
    count = 0
    target_hour = 21
    today_start = Time.current.beginning_of_day

    DeviceToken
      .where('last_active_at > ?', 7.days.ago)
      .where('last_daily_completed_at IS NULL OR last_daily_completed_at < ?', today_start)
      .find_each do |device|

      user_time = Time.current.in_time_zone(device.timezone || 'Europe/Paris')
      next unless user_time.hour == target_hour

      title = device.locale == 'fr' ? '🔥 Ne brisez pas votre série !' : '🔥 Don\'t break your streak!'
      body  = device.locale == 'fr' ? 'Il reste du temps pour le défi du jour' : 'You still have time to complete today\'s challenge'

      success = FcmService.send_notification(
        token: device.token,
        title: title,
        body:  body,
        data:  { type: 'streak_reminder' }
      )
      count += 1 if success
    end

    Rails.logger.info "✅ Streak reminder: sent #{count} notifications"
  end

  def self.re_engagement
    Rails.logger.info "📬 Sending re-engagement notifications..."
    count = 0
    target_hour = 10  # 10am user local time

    DeviceToken
      .where('last_active_at < ?', 3.days.ago)
      .where('last_active_at > ?', 7.days.ago)
      .find_each do |device|

      user_time = Time.current.in_time_zone(device.timezone || 'Europe/Paris')
      next unless user_time.hour == target_hour

      title = device.locale == 'fr' ? 'Vous nous manquez !' : 'We miss you!'
      body  = device.locale == 'fr' ? 'Revenez résoudre le cipher anime du jour' : 'Come back and solve today\'s anime cipher'

      success = FcmService.send_notification(
        token: device.token,
        title: title,
        body:  body,
        data:  { type: 're_engagement' }
      )
      count += 1 if success
    end

    Rails.logger.info "✅ Re-engagement: sent #{count} notifications"
  end
end

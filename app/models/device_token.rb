# app/models/device_token.rb
class DeviceToken < ApplicationRecord
  validates :token,    presence: true, uniqueness: true
  validates :platform, presence: true

  scope :android,  -> { where(platform: 'android') }
  scope :active,   -> { where('last_active_at > ?', 30.days.ago) }
  scope :by_locale, ->(locale) { where(locale: locale) }
end

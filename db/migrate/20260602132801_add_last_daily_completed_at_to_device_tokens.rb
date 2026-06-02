class AddLastDailyCompletedAtToDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :device_tokens, :last_daily_completed_at, :datetime
  end
end

# db/migrate/XXXXXX_create_device_tokens.rb
class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens do |t|
      t.string  :token,          null: false
      t.string  :platform,       null: false, default: 'android'
      t.string  :locale,         null: false, default: 'en'
      t.datetime :last_active_at
      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
  end
end

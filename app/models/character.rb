# app/models/character.rb
class Character < ApplicationRecord
  belongs_to :anime
  has_many :puzzles, dependent: :nullify

  validates :name, presence: true

  # ✅ Get name for specific locale
  def name_for(locale)
    names[locale.to_s] || names['en'] || name
  end

  def all_names
    result = names.presence || {}
    # Always include English from the `name` column if missing
    result = result.merge('en' => name) if result['en'].blank? && name.present?
    result
  end

  # ✅ Check if locale is available
  def locale_available?(locale)
    names.present? && names.key?(locale.to_s)
  end

  # ✅ Available locales for this character
  def available_locales
    names.present? ? names.keys : []
  end

  # ✅ Add translation for new locale
  def add_translation!(locale, name_text)
    self.names = (names || {}).merge(locale => name_text.strip)
    save!
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [
      "name", "name_japanese", "bio", "voice_actor", "voice_actor_japanese",
      "anime_id",
      "created_at", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["anime"]
  end
end

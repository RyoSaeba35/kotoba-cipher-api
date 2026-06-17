# app/models/character.rb
class Character < ApplicationRecord
  belongs_to :work
  has_many :puzzles, dependent: :nullify

  validates :name, presence: true

  def name_for(locale)
    names[locale.to_s] || names['en'] || name
  end

  def all_names
    result = names.presence || {}
    result = result.merge('en' => name) if result['en'].blank? && name.present?
    result
  end

  def locale_available?(locale)
    names.present? && names.key?(locale.to_s)
  end

  def available_locales
    names.present? ? names.keys : []
  end

  def add_translation!(locale, name_text)
    self.names = (names || {}).merge(locale => name_text.strip)
    save!
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "name", "name_original", "bio", "voice_actor", "voice_actor_japanese",
      "work_id",
      "created_at", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["work"]
  end
end

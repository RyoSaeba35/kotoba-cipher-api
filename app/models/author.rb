# app/models/author.rb
class Author < ApplicationRecord
  has_many :puzzles, dependent: :nullify

  validates :name, presence: true

  def bio_for(locale)
    bios[locale.to_s] || bios['en'] || bio
  end

  def locale_available?(locale)
    bios.present? && bios.key?(locale.to_s)
  end

  def available_locales
    bios.present? ? bios.keys : []
  end

  def add_translation!(locale, bio_text)
    self.bios = (bios || {}).merge(locale => bio_text.strip)
    save!
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name", "bio", "image_url", "wikipedia_url", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

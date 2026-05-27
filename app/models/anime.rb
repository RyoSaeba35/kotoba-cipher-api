# app/models/anime.rb
class Anime < ApplicationRecord
  has_many :puzzles, dependent: :nullify
  has_many :characters, dependent: :nullify

  validates :title, presence: true, uniqueness: true
  validates :anime_type, inclusion: { in: %w[anime manga] }

  # Scopes
  scope :anime_only, -> { where(anime_type: 'anime') }
  scope :manga_only, -> { where(anime_type: 'manga') }

  # ✅ Get title for specific locale
  def title_for(locale)
    titles[locale.to_s] || titles['en'] || title
  end

  # ✅ Check if locale is available
  def locale_available?(locale)
    titles.present? && titles.key?(locale.to_s)
  end

  # ✅ Available locales for this anime
  def available_locales
    titles.present? ? titles.keys : []
  end

  # ✅ Add translation for new locale
  def add_translation!(locale, title_text)
    self.titles = (titles || {}).merge(locale => title_text.strip)
    save!
  end

  # app/models/anime.rb
  def all_titles
    result = titles.presence || {}
    result = result.merge('en' => title) if result['en'].blank? && title.present?
    result
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["title", "title_japanese", "creator", "studio", "year", "anime_type", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["puzzles", "characters"]
  end
end

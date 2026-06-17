# app/models/work.rb
class Work < ApplicationRecord
  has_many :puzzles, dependent: :nullify
  has_many :characters, dependent: :nullify

  validates :title, presence: true, uniqueness: true
  validates :work_type, inclusion: { in: %w[anime manga book philosophy] }

  scope :anime_only, -> { where(work_type: 'anime') }
  scope :manga_only, -> { where(work_type: 'manga') }
  scope :books_only, -> { where(work_type: 'book') }
  scope :philosophy_only, -> { where(work_type: 'philosophy') }

  def title_for(locale)
    titles[locale.to_s] || titles['en'] || title
  end

  def locale_available?(locale)
    titles.present? && titles.key?(locale.to_s)
  end

  def available_locales
    titles.present? ? titles.keys : []
  end

  def add_translation!(locale, title_text)
    self.titles = (titles || {}).merge(locale => title_text.strip)
    save!
  end

  def all_titles
    result = titles.presence || {}
    result = result.merge('en' => title) if result['en'].blank? && title.present?
    result
  end

  def self.ransackable_attributes(auth_object = nil)
    ["title", "title_original", "creator", "studio", "year", "work_type", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["puzzles", "characters"]
  end
end

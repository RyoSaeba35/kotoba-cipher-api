# app/models/anime.rb
class Anime < ApplicationRecord
  has_many :puzzles
  has_many :characters

  validates :title, presence: true, uniqueness: true
  validates :anime_type, inclusion: { in: %w[anime manga] }

  # Scopes
  scope :anime_only, -> { where(anime_type: 'anime') }
  scope :manga_only, -> { where(anime_type: 'manga') }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["title", "title_japanese", "creator", "studio", "year", "anime_type", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["puzzles", "characters"]
  end
end

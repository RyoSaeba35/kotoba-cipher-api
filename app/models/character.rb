# app/models/character.rb
class Character < ApplicationRecord
  belongs_to :anime
  has_many :puzzles

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [
      "name", "name_japanese", "bio", "voice_actor", "voice_actor_japanese",
      "anime_id",  # ← ADD THIS! (foreign key for belongs_to)
      "created_at", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["anime"]  # Keep belongs_to, remove has_many
  end
end

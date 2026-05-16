# app/models/author.rb
class Author < ApplicationRecord
  has_many :puzzles

  validates :name, presence: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["name", "bio", "image_url", "wikipedia_url", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    []  # Remove "puzzles" - can't filter has_many this way
  end
end

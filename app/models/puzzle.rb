# app/models/puzzle.rb
class Puzzle < ApplicationRecord
  belongs_to :anime
  belongs_to :character, optional: true
  belongs_to :author, optional: true

  # Callbacks - Auto-generate cipher when puzzle is created
  before_create :generate_cipher_and_encrypt
  before_create :select_starting_letters
  before_create :generate_hints

  # Validations
  validates :solution, presence: true, length: { minimum: 10, maximum: 300 }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }
  validates :points, numericality: { greater_than: 0 }

  # Scopes
  scope :by_difficulty, ->(diff) { where(difficulty: diff) }
  scope :daily, -> { where(featured_date: Date.today) }
  scope :recent, -> { order(created_at: :desc) }

  # Ransack configuration for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    [
      "solution", "topic", "difficulty", "artwork", "featured_date",
      "anime_id", "character_id", "author_id",  # Add foreign keys!
      "created_at", "updated_at", "points"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["anime", "author", "character"]
  end

  private

  # Generate cipher mapping and encrypt text
  def generate_cipher_and_encrypt
    self.cipher_mapping = CipherGenerator.generate
    self.encrypted_text = CipherGenerator.encrypt(solution, cipher_mapping)
  end

  # Select starting letters based on difficulty
  def select_starting_letters
    count = case difficulty
            when 'easy' then 3
            when 'medium' then 2
            when 'hard' then 1
            else 2
            end

    self.starting_letters = StartingLetterSelector.select(
      solution: solution,
      count: count,
      cipher_mapping: cipher_mapping
    )
  end

  # Generate hint structure
  def generate_hints
    letter_hints = []
    word_hints = []

    # Get unique letters from solution
    unique_letters = solution.upcase.scan(/[A-Z]/).uniq

    # Create reveal_letter hints for most common letters
    letter_frequency = solution.upcase.scan(/[A-Z]/).tally.sort_by { |k, v| -v }
    letter_frequency.first(5).each do |letter, _count|
      letter_hints << {
        type: 'reveal_letter',
        letter: letter,
        cost: 10
      }
    end

    # Create reveal_word hints for words with 4+ letters
    words = solution.upcase.scan(/[A-Z]+/).select { |w| w.length >= 4 }
    words.uniq.first(3).each do |word|
      word_hints << {
        type: 'reveal_word',
        word: word,
        cost: 25
      }
    end

    self.hints = letter_hints + word_hints
  end
end

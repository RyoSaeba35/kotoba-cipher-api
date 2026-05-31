# app/models/puzzle.rb
class Puzzle < ApplicationRecord
  belongs_to :anime
  belongs_to :character, optional: true
  belongs_to :author, optional: true

  # ✅ Supported locales
  SUPPORTED_LOCALES = %w[en fr es de it pt].freeze

  # ✅ Callbacks
  before_create :set_default_locale
  before_create :normalize_solutions
  before_create :generate_all_ciphers
  before_create :generate_all_hints
  before_save :regenerate_ciphers_if_solutions_changed

  # ✅ Validations
  validates :default_locale, inclusion: { in: SUPPORTED_LOCALES }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }
  validates :points, numericality: { greater_than: 0 }

  validates :solution, format: {
    with: /\A[A-Z0-9\s\.\,\'\!\?\-]+\z/,  # ✅ Added \- for hyphen
    message: "can only contain letters, numbers, spaces, and punctuation (.,\'!?-)",
    allow_blank: true
  }

  # Scopes
  scope :by_difficulty, ->(diff) { where(difficulty: diff) }
  scope :daily, -> { where(featured_date: Date.today) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_locale, ->(locale) { where("solutions ? :locale", locale: locale) }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["topic", "difficulty", "artwork", "featured_date",
     "anime_id", "character_id", "author_id",
     "created_at", "updated_at", "points", "default_locale"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["anime", "author", "character"]
  end

  # ✅ Get solution for specific locale
  def solution_for(locale)
    solutions[locale.to_s] || solutions[default_locale] || solutions['en']
  end

  # ✅ Get encrypted text for specific locale
  def encrypted_text_for(locale)
    encrypted_texts[locale.to_s] || encrypted_texts[default_locale] || encrypted_texts['en']
  end

  # ✅ Get cipher mapping for specific locale
  def cipher_mapping_for(locale)
    cipher_mappings_i18n[locale.to_s] || cipher_mappings_i18n[default_locale] || cipher_mappings_i18n['en']
  end

  # ✅ Get starting letters for specific locale
  def starting_letters_for(locale)
    starting_letters_i18n[locale.to_s] || starting_letters_i18n[default_locale] || starting_letters_i18n['en']
  end

  # ✅ Get hints for specific locale
  def hints_for(locale)
    hints_i18n[locale.to_s] || hints_i18n[default_locale] || hints_i18n['en']
  end

  # ✅ Check if locale is available
  def locale_available?(locale)
    solutions.key?(locale.to_s)
  end

  # ✅ Available locales for this puzzle
  def available_locales
    solutions.keys
  end

  # ✅ Add translation for new locale
  def add_translation!(locale, solution_text)
    normalized = solution_text.strip.upcase

    # Validate format
    unless normalized.match?(/\A[A-Z0-9\s\.\,\'\!\?\-]+\z/)
      raise ArgumentError, "Invalid solution format"
    end

    # Generate cipher for this locale
    cipher = CipherGenerator.generate
    encrypted = CipherGenerator.encrypt(normalized, cipher)

    # Select starting letters
    count = case difficulty
            when 'easy' then 3
            when 'medium' then 2
            when 'hard' then 1
            else 2
            end

    starting = StartingLetterSelector.select(
      solution: normalized,
      count: count,
      cipher_mapping: cipher
    )

    # Generate hints
    hints = generate_hints_for_solution(normalized)

    # Update JSONB columns
    self.solutions = solutions.merge(locale => normalized)
    self.encrypted_texts = encrypted_texts.merge(locale => encrypted)
    self.cipher_mappings_i18n = cipher_mappings_i18n.merge(locale => cipher)
    self.starting_letters_i18n = starting_letters_i18n.merge(locale => starting)
    self.hints_i18n = hints_i18n.merge(locale => hints)

    save!
  end

  private

  def set_default_locale
    self.default_locale ||= 'en'
  end

  def normalize_solutions
    # Normalize solution if using old column (backwards compatibility)
    if solution.present?
      self.solutions = { default_locale => solution.strip.upcase }
    end

    # Normalize all solutions in JSONB
    self.solutions = solutions.transform_values { |v| v.strip.upcase }
  end

  def generate_all_ciphers
    solutions.each do |locale, solution_text|
      next if encrypted_texts[locale].present? # Skip if already exists

      cipher = CipherGenerator.generate
      encrypted = CipherGenerator.encrypt(solution_text, cipher)

      count = case difficulty
              when 'easy' then 3
              when 'medium' then 2
              when 'hard' then 1
              else 2
              end

      starting = StartingLetterSelector.select(
        solution: solution_text,
        count: count,
        cipher_mapping: cipher
      )

      self.encrypted_texts = (encrypted_texts || {}).merge(locale => encrypted)
      self.cipher_mappings_i18n = (cipher_mappings_i18n || {}).merge(locale => cipher)
      self.starting_letters_i18n = (starting_letters_i18n || {}).merge(locale => starting)
    end
  end

  def generate_all_hints
    solutions.each do |locale, solution_text|
      next if hints_i18n[locale].present? # Skip if already exists

      hints = generate_hints_for_solution(solution_text)
      self.hints_i18n = (hints_i18n || {}).merge(locale => hints)
    end
  end

  def generate_hints_for_solution(solution_text)
    # Letter hints
    letter_frequency = solution_text.scan(/[A-Z]/).tally.sort_by { |k, v| -v }
    letter_hints = letter_frequency.first(5).map do |letter, _count|
      { type: 'reveal_letter', letter: letter, cost: 10 }
    end

    # Word hints
    words = solution_text.scan(/[A-Z]+/).select { |w| w.length >= 4 }
    word_hints = words.uniq.first(3).map do |word|
      { type: 'reveal_word', word: word, cost: 25 }
    end

    letter_hints + word_hints
  end

  def regenerate_ciphers_if_solutions_changed
    return unless solutions_changed?

    solutions.each do |locale, solution_text|
      cipher = CipherGenerator.generate
      encrypted = CipherGenerator.encrypt(solution_text, cipher)
      count = case difficulty
              when 'easy' then 3
              when 'medium' then 2
              when 'hard' then 1
              else 2
              end
      starting = StartingLetterSelector.select(
        solution: solution_text,
        count: count,
        cipher_mapping: cipher
      )
      hints = generate_hints_for_solution(solution_text)

      self.encrypted_texts = (encrypted_texts || {}).merge(locale => encrypted)
      self.cipher_mappings_i18n = (cipher_mappings_i18n || {}).merge(locale => cipher)
      self.starting_letters_i18n = (starting_letters_i18n || {}).merge(locale => starting)
      self.hints_i18n = (hints_i18n || {}).merge(locale => hints)
    end
  end
end

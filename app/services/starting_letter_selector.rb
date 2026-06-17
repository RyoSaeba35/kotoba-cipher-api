# app/services/starting_letter_selector.rb
class StartingLetterSelector
  # Select which letters to reveal at game start
  def self.select(solution:, count:, cipher_mapping:)
    # Calculate letter frequency in the solution
    letter_frequency = calculate_frequency(solution)

    # Select most common letters
    selected_letters = letter_frequency.keys.first(count)

    # Return array of hashes with encrypted and actual letters
    selected_letters.map do |letter|
      {
        'encrypted' => cipher_mapping[letter],
        'actual' => letter
      }
    end
  end

  private

  # Calculate letter frequency (most to least common)
  def self.calculate_frequency(text)
    letters = text.upcase.scan(/[A-Z]/)
    frequency = letters.tally

    frequency.sort_by { |letter, count| -count }.to_h
  end
end

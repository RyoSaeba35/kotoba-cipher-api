# app/services/cipher_generator.rb
class CipherGenerator
  ALPHABET = ('A'..'Z').to_a

  # Generate random substitution cipher
  def self.generate
    shuffled = ALPHABET.dup

    # Keep shuffling until no letter maps to itself
    loop do
      shuffled.shuffle!
      break unless has_identity_mapping?(ALPHABET, shuffled)
    end

    # Create mapping hash: { "A" => "X", "B" => "Y", ... }
    ALPHABET.zip(shuffled).to_h
  end

  # Encrypt text
  def self.encrypt(text, cipher_mapping)
    text.upcase.chars.map do |char|
      # Encrypt letters, keep spaces and punctuation
      if char.match?(/[A-Z]/)
        cipher_mapping[char]
      else
        char
      end
    end.join
  end

  # Decrypt text
  def self.decrypt(encrypted_text, cipher_mapping)
    reverse_mapping = cipher_mapping.invert

    encrypted_text.upcase.chars.map do |char|
      if char.match?(/[A-Z]/)
        reverse_mapping[char]
      else
        char
      end
    end.join
  end

  private

  # Check if any letter maps to itself
  def self.has_identity_mapping?(original, shuffled)
    original.each_with_index.any? { |letter, i| letter == shuffled[i] }
  end
end

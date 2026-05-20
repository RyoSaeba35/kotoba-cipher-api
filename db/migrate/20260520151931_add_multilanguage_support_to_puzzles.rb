class AddMultilanguageSupportToPuzzles < ActiveRecord::Migration[8.1]
  def change
    # ✅ Puzzles: Add JSONB columns for multilanguage support
    add_column :puzzles, :solutions, :jsonb, default: {}
    add_column :puzzles, :encrypted_texts, :jsonb, default: {}
    add_column :puzzles, :cipher_mappings_i18n, :jsonb, default: {}
    add_column :puzzles, :starting_letters_i18n, :jsonb, default: {}
    add_column :puzzles, :hints_i18n, :jsonb, default: {}
    add_column :puzzles, :default_locale, :string, default: 'en'

    # Add indexes for better query performance
    add_index :puzzles, :solutions, using: :gin
    add_index :puzzles, :default_locale

    # ✅ Animes: Add multilanguage titles
    add_column :animes, :titles, :jsonb, default: {}
    add_index :animes, :titles, using: :gin

    # ✅ Characters: Add multilanguage names
    add_column :characters, :names, :jsonb, default: {}
    add_index :characters, :names, using: :gin

    # ✅ Authors: Add multilanguage bios
    add_column :authors, :bios, :jsonb, default: {}
    add_index :authors, :bios, using: :gin
  end
end

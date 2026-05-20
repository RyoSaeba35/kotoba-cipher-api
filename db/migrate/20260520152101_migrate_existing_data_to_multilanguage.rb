class MigrateExistingDataToMultilanguage < ActiveRecord::Migration[8.1]
  def up
    # Migrate puzzles
    Puzzle.find_each do |puzzle|
      puzzle.update_columns(
        solutions: { en: puzzle.solution },
        encrypted_texts: { en: puzzle.encrypted_text },
        cipher_mappings_i18n: { en: puzzle.cipher_mapping },
        starting_letters_i18n: { en: puzzle.starting_letters },
        hints_i18n: { en: puzzle.hints },
        default_locale: 'en'
      )
    end

    # Migrate animes
    Anime.find_each do |anime|
      titles_hash = { en: anime.title }
      titles_hash[:ja] = anime.title_japanese if anime.title_japanese.present?
      anime.update_column(:titles, titles_hash)
    end

    # Migrate characters
    Character.find_each do |character|
      names_hash = { en: character.name }
      names_hash[:ja] = character.name_japanese if character.name_japanese.present?
      character.update_column(:names, names_hash)
    end

    # Migrate authors
    Author.find_each do |author|
      author.update_column(:bios, { en: author.bio }) if author.bio.present?
    end

    say "✅ Migrated #{Puzzle.count} puzzles to multilanguage format"
    say "✅ Migrated #{Anime.count} animes to multilanguage format"
    say "✅ Migrated #{Character.count} characters to multilanguage format"
    say "✅ Migrated #{Author.count} authors to multilanguage format"
  end

  def down
    # Rollback not needed - keeps old columns intact
    say "⚠️  Old columns preserved - no data loss"
  end
end

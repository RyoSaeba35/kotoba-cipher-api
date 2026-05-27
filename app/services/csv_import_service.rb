# app/services/csv_import_service.rb
require 'csv'

class CsvImportService
  def self.import(file_path, type)
    case type
    when 'authors'
      import_authors(file_path)
    when 'animes'
      import_animes(file_path)
    when 'characters'
      import_characters(file_path)
    when 'puzzles'
      import_puzzles(file_path)
    else
      raise "Unknown import type: #{type}"
    end
  end

  private

  def self.normalize(str)
    result = str.strip.upcase
                .unicode_normalize(:nfc)
    result = ActiveSupport::Inflector.transliterate(result)
    result.gsub(/[^\x00-\x7F]/, '')  # strip any remaining non-ASCII
  end

  def self.import_authors(file_path)
    count = 0
    CSV.foreach(file_path, headers: true) do |row|
      Author.find_or_create_by!(name: row['name']) do |author|
        author.bio           = row['bio'] || row['bio_en']
        author.image_url     = row['image_url']
        author.wikipedia_url = row['wikipedia_url']

        bios = {}
        bios['en'] = row['bio_en'].strip if row['bio_en'].present?
        bios['fr'] = row['bio_fr'].strip if row['bio_fr'].present?
        bios['es'] = row['bio_es'].strip if row['bio_es'].present?
        author.bios = bios if bios.any?

        count += 1
      end
    end
    { count: count, message: "" }
  end

  def self.import_animes(file_path)
    count = 0
    CSV.foreach(file_path, headers: true) do |row|
      Anime.find_or_create_by!(title: row['title']) do |anime|
        anime.title_japanese = row['title_japanese']
        anime.creator        = row['creator']
        anime.studio         = row['studio']
        anime.year           = row['year'].to_i
        anime.anime_type     = row['anime_type']
        anime.image_url      = row['image_url']

        titles = {}
        titles['fr'] = row['title_fr'].strip if row['title_fr'].present?
        titles['es'] = row['title_es'].strip if row['title_es'].present?
        anime.titles = titles if titles.any?

        count += 1
      end
    end
    { count: count, message: "" }
  end

  def self.import_characters(file_path)
    count = 0
    skipped = 0

    CSV.foreach(file_path, headers: true) do |row|
      anime = Anime.find_by(title: row['anime_title'])
      unless anime
        skipped += 1
        next
      end

      Character.find_or_create_by!(name: row['name'], anime: anime) do |character|
        character.name_japanese        = row['name_japanese']
        character.voice_actor          = row['voice_actor']
        character.voice_actor_japanese = row['voice_actor_japanese']
        character.bio                  = row['bio']
        character.image_url            = row['image_url']

        names = {}
        names['fr'] = row['name_fr'].strip if row['name_fr'].present?
        names['es'] = row['name_es'].strip if row['name_es'].present?
        character.names = names if names.any?

        count += 1
      end
    end

    message = skipped > 0 ? "(#{skipped} skipped - anime not found)" : ""
    { count: count, message: message }
  end

  # ✅ UPDATED: Multilanguage support
  def self.import_puzzles(file_path)
    count = 0
    skipped = 0
    errors = []

    CSV.foreach(file_path, headers: true).with_index(2) do |row, line_number|
      anime = Anime.find_by(title: row['anime_title'])

      unless anime
        skipped += 1
        errors << "Line #{line_number}: Anime '#{row['anime_title']}' not found"
        next
      end

      character = Character.find_by(name: row['character_name'])
      author    = row['author_name'].present? ? Author.find_by(name: row['author_name']) : nil

      # ✅ Build solutions hash from CSV columns
      solutions_hash = {}

      # English (required)
      if row['solution_en'].present?
        solutions_hash['en'] = normalize(row['solution_en'])
      elsif row['solution'].present?
        solutions_hash['en'] = normalize(row['solution'])
      else
        errors << "Line #{line_number}: Missing English solution"
        next
      end

      # French (optional)
      solutions_hash['fr'] = normalize(row['solution_fr']) if row['solution_fr'].present?

      # Spanish (optional)
      solutions_hash['es'] = normalize(row['solution_es']) if row['solution_es'].present?

      # German (optional)
      solutions_hash['de'] = normalize(row['solution_de']) if row['solution_de'].present?

      # Italian (optional)
      solutions_hash['it'] = normalize(row['solution_it']) if row['solution_it'].present?

      # Portuguese (optional)
      solutions_hash['pt'] = normalize(row['solution_pt']) if row['solution_pt'].present?


      # Check for duplicates (use English solution)
      existing = Puzzle.find_by("solutions->>'en' = ?", solutions_hash['en'])
      if existing && existing.anime_id == anime.id
        skipped += 1
        next
      end

      # ✅ Create puzzle with multilanguage solutions
      Puzzle.create!(
        solutions:     solutions_hash,  # ✅ JSONB with all languages
        anime:         anime,
        character:     character,
        author:        author,
        topic:         row['topic'],
        difficulty:    row['difficulty'] || 'medium',
        points:        row['points'].to_i.positive? ? row['points'].to_i : 100,
        artwork:       row['artwork'],
        video_url:     row['video_url'],
        featured_date: row['featured_date'].present? ? Date.parse(row['featured_date']) : nil,
        default_locale: 'en'
      )

      count += 1
    rescue => e
      errors << "Line #{line_number}: #{e.message}"
    end

    message  = skipped > 0 ? "(#{skipped} skipped)" : ""
    message += " #{errors.count} error(s)." if errors.any?

    { count: count, message: message, errors: errors }
  end
end

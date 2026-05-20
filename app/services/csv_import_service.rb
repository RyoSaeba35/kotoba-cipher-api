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

  def self.import_authors(file_path)
    count = 0
    CSV.foreach(file_path, headers: true) do |row|
      Author.find_or_create_by!(name: row['name']) do |author|
        author.bio           = row['bio']
        author.image_url     = row['image_url']
        author.wikipedia_url = row['wikipedia_url']
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
        anime.image_url      = row['image_url']  # ← added
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
        character.image_url            = row['image_url']  # ← added
        count += 1
      end
    end

    message = skipped > 0 ? "(#{skipped} skipped - anime not found)" : ""
    { count: count, message: message }
  end

  # app/services/csv_import_service.rb
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

      # ✅ Normalize solution (model will handle it in before_create, but check here for duplicates)
      normalized_solution = row['solution'].strip.upcase

      existing = Puzzle.find_by(solution: normalized_solution, anime: anime)
      if existing
        skipped += 1
        next
      end

      # ✅ Model callbacks will auto-generate cipher, starting letters, and hints
      Puzzle.create!(
        solution:      row['solution'],  # ✅ Pass as-is, model normalizes it
        anime:         anime,
        character:     character,
        author:        author,
        topic:         row['topic'],
        difficulty:    row['difficulty'] || 'medium',
        points:        row['points'].to_i.positive? ? row['points'].to_i : 100,
        artwork:       row['artwork'],
        video_url:     row['video_url'],
        featured_date: row['featured_date'].present? ? Date.parse(row['featured_date']) : nil
      )

      count += 1
    rescue => e
      errors << "Line #{line_number}: #{e.message}"
    end

    message  = skipped > 0 ? "(#{skipped} skipped)" : ""
    message += " Errors: #{errors.join(', ')}" if errors.any?

    { count: count, message: message }
  end
end

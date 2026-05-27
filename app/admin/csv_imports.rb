# app/admin/csv_imports.rb
ActiveAdmin.register_page "CSV Import" do
  menu priority: 2, label: "📂 CSV Import"

  content title: "Import Data from CSV" do
    panel "Upload CSV Files" do
      para "Import authors, anime, characters, and puzzles from CSV files."
      para "You can upload files one at a time or all at once."

      render partial: 'admin/csv_imports/upload_form'
    end

    # Instructions panel
    panel "CSV Format Instructions" do
      h3 "File Templates"

      div class: "csv-templates" do
        h4 "1. Authors CSV"
        pre do
          text_node "name,bio,image_url,wikipedia_url\n"
          text_node "Hayao Miyazaki,Japanese animator...,https://...,https://..."
        end

        h4 "2. Animes CSV"
        pre do
          text_node "title,title_japanese,creator,studio,year,anime_type,image_url\n"
          text_node "Spirited Away,千と千尋の神隠し,Hayao Miyazaki,Studio Ghibli,2001,anime,https://..."
        end

        h4 "3. Characters CSV"
        pre do
          text_node "name,name_japanese,anime_title,voice_actor,voice_actor_japanese,bio,image_url\n"
          text_node "Chihiro,荻野千尋,Spirited Away,Daveigh Chase,Rumi Hiiragi,A brave girl...,https://..."
        end

        h4 "4. Puzzles CSV (Multilanguage)"
        pre do
          # ✅ Updated with multilanguage columns
          text_node "solution_en,solution_fr,anime_title,character_name,author_name,topic,difficulty,points,artwork,video_url,featured_date\n"
          text_node "NEVER GIVE UP,N'ABANDONNE JAMAIS,Naruto,Naruto Uzumaki,Masashi Kishimoto,Perseverance,medium,100,Naruto,,\n"
          text_node "BELIEVE IN YOURSELF,CROIS EN TOI-MEME,Fairy Tail,Mavis Vermillion,,Confidence,hard,150,Fairy Tail,,2025-12-25"
        end
      end

      div style: "margin-top: 20px;" do
        para do
          strong "Import Order: "
          text_node "Authors → Animes → Characters → Puzzles"
        end
        para do
          strong "Multilanguage Note: "
          text_node "solution_en is required. solution_fr, solution_es, solution_de, solution_it, solution_pt are optional. Use uppercase, no accents."
        end
      end
    end
  end

  # Handle CSV upload (no changes needed)
  page_action :upload, method: :post do
    file = params[:csv_file]
    file_type = params[:file_type]

    if file.blank?
      redirect_to admin_csv_import_path, alert: "Please select a file to upload"
      return
    end

    begin
      result = CsvImportService.import(file.path, file_type)
      Rails.logger.info("[CSV Import] #{file_type}: #{result[:count]} imported. Errors: #{Array(result[:errors]).join(' | ')}")

      msg = "✅ Imported #{result[:count]} #{file_type}."
      msg += " #{result[:errors].count} error(s) — check server logs." if result[:errors]&.any?

      redirect_to admin_csv_import_path, notice: msg
    rescue => e
      Rails.logger.error("[CSV Import] Failed: #{e.message}")
      redirect_to admin_csv_import_path, alert: "❌ Import failed: #{e.message.truncate(200)}"
    end
  end

  # Download CSV template
  page_action :download_template, method: :get do
    type = params[:type]

    csv_data = case type
    when 'authors'
      generate_authors_template
    when 'animes'
      generate_animes_template
    when 'characters'
      generate_characters_template
    when 'puzzles'
      generate_puzzles_template
    else
      redirect_to admin_csv_import_path, alert: "Unknown template type"
      return
    end

    send_data csv_data,
              filename: "#{type}_template.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  # Export current database as CSV
  page_action :export, method: :get do
    type = params[:type]

    csv_data = case type
    when 'authors'
      export_authors
    when 'animes'
      export_animes
    when 'characters'
      export_characters
    when 'puzzles'
      export_puzzles
    else
      redirect_to admin_csv_import_path, alert: "Unknown export type"
      return
    end

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    send_data csv_data,
              filename: "#{type}_export_#{timestamp}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  # Template generation helpers
  controller do
    def generate_authors_template
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'bio', 'image_url', 'wikipedia_url']
        csv << ['Hayao Miyazaki', 'Japanese animator and filmmaker. Co-founder of Studio Ghibli.', 'https://example.com/miyazaki.jpg', 'https://en.wikipedia.org/wiki/Hayao_Miyazaki']
        csv << ['Tsukasa Hojo', 'Japanese manga artist known for City Hunter and Angel Heart.', 'https://example.com/hojo.jpg', 'https://en.wikipedia.org/wiki/Tsukasa_Hojo']
      end
    end

    def generate_animes_template
      CSV.generate(headers: true) do |csv|
        csv << ['title', 'title_japanese', 'creator', 'studio', 'year', 'anime_type', 'image_url']
        csv << ['Spirited Away', '千と千尋の神隠し', 'Hayao Miyazaki', 'Studio Ghibli', '2001', 'anime', 'https://example.com/anime/spirited_away.jpg']
      end
    end

    def generate_characters_template
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'name_japanese', 'anime_title', 'voice_actor', 'voice_actor_japanese', 'bio', 'image_url']
        csv << ['Chihiro Ogino', '荻野千尋', 'Spirited Away', 'Daveigh Chase', 'Rumi Hiiragi', 'A brave young girl', 'https://example.com/characters/chihiro.jpg']
      end
    end

    # ✅ UPDATED: Multilanguage puzzle template
    def generate_puzzles_template
      CSV.generate(headers: true) do |csv|
        csv << ['solution_en', 'solution_fr', 'anime_title', 'character_name', 'author_name', 'topic', 'difficulty', 'points', 'artwork', 'video_url', 'featured_date']
        csv << ['ALWAYS BELIEVE IN YOURSELF', 'CROIS TOUJOURS EN TOI-MEME', 'Spirited Away', 'Haku', '', 'Courage', 'hard', '150', 'Spirited Away', '', '']
        csv << ['NEVER GIVE UP', "N'ABANDONNE JAMAIS", 'Naruto', 'Naruto Uzumaki', 'Masashi Kishimoto', 'Perseverance', 'medium', '100', 'Naruto', '', '']
      end
    end

    # Export methods
    def export_authors
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'bio_en', 'bio_fr', 'bio_es', 'image_url', 'wikipedia_url']
        Author.find_each do |author|
          csv << [
            author.name,
            author.bios['en'] || author.bio,
            author.bios['fr'],
            author.bios['es'],
            author.image_url,
            author.wikipedia_url
          ]
        end
      end
    end

    def export_animes
      CSV.generate(headers: true) do |csv|
        csv << ['title', 'title_fr', 'title_es', 'title_japanese', 'creator', 'studio', 'year', 'anime_type', 'image_url']
        Anime.find_each do |anime|
          csv << [
            anime.title,
            anime.titles['fr'],
            anime.titles['es'],
            anime.title_japanese,
            anime.creator,
            anime.studio,
            anime.year,
            anime.anime_type,
            anime.image_url
          ]
        end
      end
    end

    def export_characters
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'name_fr', 'name_es', 'name_japanese', 'anime_title', 'voice_actor', 'voice_actor_japanese', 'bio', 'image_url']
        Character.includes(:anime).find_each do |character|
          csv << [
            character.name,
            character.names['fr'],
            character.names['es'],
            character.name_japanese,
            character.anime&.title,
            character.voice_actor,
            character.voice_actor_japanese,
            character.bio,
            character.image_url
          ]
        end
      end
    end

    # ✅ UPDATED: Export puzzles with multilanguage columns
    def export_puzzles
      CSV.generate(headers: true) do |csv|
        csv << ['solution_en', 'solution_fr', 'anime_title', 'character_name', 'author_name', 'topic', 'difficulty', 'points', 'artwork', 'video_url', 'featured_date']
        Puzzle.includes(:anime, :character, :author).find_each do |puzzle|
          csv << [
            puzzle.solution_for('en'),
            puzzle.solution_for('fr'),
            puzzle.anime&.title,
            puzzle.character&.name,
            puzzle.author&.name,
            puzzle.topic,
            puzzle.difficulty,
            puzzle.points,
            puzzle.artwork,
            puzzle.video_url,
            puzzle.featured_date
          ]
        end
      end
    end
  end
end

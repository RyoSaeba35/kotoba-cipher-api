# app/admin/csv_imports.rb
ActiveAdmin.register_page "CSV Import" do
  menu priority: 2, label: "📂 CSV Import"

  content title: "Import Data from CSV" do
    panel "Upload CSV Files" do
      para "Import authors, works, characters, and puzzles from CSV files."
      para "You can upload files one at a time or all at once."

      render partial: 'admin/csv_imports/upload_form'
    end

    panel "CSV Format Instructions" do
      h3 "File Templates"

      div class: "csv-templates" do
        h4 "1. Authors CSV"
        pre do
          text_node "name,bio,image_url,wikipedia_url\n"
          text_node "Sun Tzu,Chinese military strategist...,https://...,https://..."
        end

        h4 "2. Works CSV"
        pre do
          text_node "title,title_original,creator,studio,year,work_type,image_url\n"
          text_node "The Art of War,孫子兵法,Sun Tzu,,500 BC,philosophy,https://..."
        end

        h4 "3. Characters CSV"
        pre do
          text_node "name,name_original,work_title,voice_actor,voice_actor_japanese,bio,image_url\n"
          text_node "Chihiro,荻野千尋,Spirited Away,Daveigh Chase,Rumi Hiiragi,A brave girl...,https://..."
        end

        h4 "4. Puzzles CSV (Multilanguage)"
        pre do
          text_node "solution_en,solution_fr,work_title,character_name,author_name,topic,difficulty,points,artwork,video_url,featured_date\n"
          text_node "NEVER GIVE UP,N'ABANDONNE JAMAIS,Naruto,Naruto Uzumaki,Masashi Kishimoto,Perseverance,medium,100,Naruto,,\n"
          text_node "KNOW YOURSELF,CONNAIS-TOI TOI-MEME,The Art of War,,Sun Tzu,Wisdom,hard,150,,,2025-12-25"
        end
      end

      div style: "margin-top: 20px;" do
        para do
          strong "Import Order: "
          text_node "Authors → Works → Characters → Puzzles"
        end
        para do
          strong "Multilanguage Note: "
          text_node "solution_en is required. solution_fr, solution_es, solution_de, solution_it, solution_pt are optional. Use uppercase, no accents."
        end
      end
    end
  end

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

      msg = "Imported #{result[:count]} #{file_type}."
      msg += " #{result[:errors].count} error(s) — check server logs." if result[:errors]&.any?

      redirect_to admin_csv_import_path, notice: msg
    rescue => e
      Rails.logger.error("[CSV Import] Failed: #{e.message}")
      redirect_to admin_csv_import_path, alert: "❌ Import failed: #{e.message.truncate(200)}"
    end
  end

  page_action :download_template, method: :get do
    type = params[:type]

    csv_data = case type
    when 'authors'    then generate_authors_template
    when 'works'      then generate_works_template
    when 'characters' then generate_characters_template
    when 'puzzles'    then generate_puzzles_template
    else
      redirect_to admin_csv_import_path, alert: "Unknown template type"
      return
    end

    send_data csv_data,
              filename: "#{type}_template.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  page_action :export, method: :get do
    type = params[:type]

    csv_data = case type
    when 'authors'    then export_authors
    when 'works'      then export_works
    when 'characters' then export_characters
    when 'puzzles'    then export_puzzles
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

  controller do
    def generate_authors_template
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'bio', 'image_url', 'wikipedia_url']
        csv << ['Sun Tzu', 'Chinese military strategist and philosopher.', 'https://example.com/suntzu.jpg', 'https://en.wikipedia.org/wiki/Sun_Tzu']
        csv << ['Miyamoto Musashi', 'Japanese swordsman and philosopher.', 'https://example.com/musashi.jpg', 'https://en.wikipedia.org/wiki/Miyamoto_Musashi']
      end
    end

    def generate_works_template
      CSV.generate(headers: true) do |csv|
        csv << ['title', 'title_original', 'creator', 'studio', 'year', 'work_type', 'image_url']
        csv << ['The Art of War', '孫子兵法', 'Sun Tzu', '', '500 BC', 'philosophy', 'https://example.com/artofwar.jpg']
        csv << ['Spirited Away', '千と千尋の神隠し', 'Hayao Miyazaki', 'Studio Ghibli', '2001', 'anime', 'https://example.com/spirited_away.jpg']
      end
    end

    def generate_characters_template
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'name_original', 'work_title', 'voice_actor', 'voice_actor_japanese', 'bio', 'image_url']
        csv << ['Chihiro Ogino', '荻野千尋', 'Spirited Away', 'Daveigh Chase', 'Rumi Hiiragi', 'A brave young girl', 'https://example.com/chihiro.jpg']
      end
    end

    def generate_puzzles_template
      CSV.generate(headers: true) do |csv|
        csv << ['solution_en', 'solution_fr', 'work_title', 'character_name', 'author_name', 'topic', 'difficulty', 'points', 'artwork', 'video_url', 'featured_date']
        csv << ['KNOW YOURSELF', 'CONNAIS-TOI TOI-MEME', 'The Art of War', '', 'Sun Tzu', 'Wisdom', 'hard', '150', 'The Art of War', '', '']
        csv << ['NEVER GIVE UP', "N'ABANDONNE JAMAIS", 'Naruto', 'Naruto Uzumaki', '', 'Perseverance', 'medium', '100', 'Naruto', '', '']
      end
    end

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

    def export_works
      CSV.generate(headers: true) do |csv|
        csv << ['title', 'title_fr', 'title_es', 'title_original', 'creator', 'studio', 'year', 'work_type', 'image_url']
        Work.find_each do |work|
          csv << [
            work.title,
            work.titles['fr'],
            work.titles['es'],
            work.title_original,
            work.creator,
            work.studio,
            work.year,
            work.work_type,
            work.image_url
          ]
        end
      end
    end

    def export_characters
      CSV.generate(headers: true) do |csv|
        csv << ['name', 'name_fr', 'name_es', 'name_original', 'work_title', 'voice_actor', 'voice_actor_japanese', 'bio', 'image_url']
        Character.includes(:work).find_each do |character|
          csv << [
            character.name,
            character.names['fr'],
            character.names['es'],
            character.name_original,
            character.work&.title,
            character.voice_actor,
            character.voice_actor_japanese,
            character.bio,
            character.image_url
          ]
        end
      end
    end

    def export_puzzles
      CSV.generate(headers: true) do |csv|
        csv << ['solution_en', 'solution_fr', 'work_title', 'character_name', 'author_name', 'topic', 'difficulty', 'points', 'artwork', 'video_url', 'featured_date']
        Puzzle.includes(:work, :character, :author).find_each do |puzzle|
          csv << [
            puzzle.solution_for('en'),
            puzzle.solution_for('fr'),
            puzzle.work&.title,
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

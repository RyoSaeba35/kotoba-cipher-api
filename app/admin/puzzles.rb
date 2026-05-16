# app/admin/puzzles.rb
ActiveAdmin.register Puzzle do

  # ✅ Fix N+1 queries
  controller do
    def scoped_collection
      super.includes(:anime, :character, :author)
    end
  end

  permit_params :solution, :topic, :difficulty, :artwork, :points,
                :anime_id, :character_id, :author_id,
                :video_url, :video_thumbnail_url, :video_duration,
                :featured_date
                # ❌ background_image_url removed — now on anime
                # ❌ character_image_url removed — now on character

  index do
    selectable_column
    id_column
    column :solution do |puzzle|
      truncate(puzzle.solution, length: 50)
    end
    column :anime
    column :character
    column :difficulty
    column :featured_date
    column :created_at
    actions
  end

  # ✅ Only filter on ransackable_attributes defined in the model
  filter :difficulty
  filter :topic
  filter :featured_date
  filter :created_at
  # ❌ filter :anime — causes Ransack issues, use the select below instead
  # ❌ filter :character — same reason

  form do |f|
    f.inputs 'Puzzle Content' do
      f.input :solution,
              label: 'Quote Text',
              hint: 'Enter the original anime quote (cipher will be auto-generated)',
              input_html: { rows: 3 }

      f.input :anime,
              label: 'Anime/Manga Source',
              as: :select,
              collection: Anime.all.order(:title).map { |a| [a.title, a.id] },
              include_blank: 'Select anime...'

      f.input :character,
              label: 'Character (optional)',
              as: :select,
              collection: Character.includes(:anime).order(:name).map { |c| ["#{c.name} (#{c.anime.title})", c.id] },
              include_blank: 'Select character...'

      f.input :author,
              label: 'Author/Creator (optional)',
              as: :select,
              collection: Author.all.order(:name).map { |a| [a.name, a.id] },
              include_blank: 'Select author...'

      f.input :artwork,
              label: 'Artwork Title',
              hint: 'Name of the anime/manga for this specific artwork'

      f.input :topic,
              label: 'Theme/Topic',
              hint: 'e.g., Perseverance, Friendship, Love, Courage'

      f.input :difficulty,
              as: :select,
              collection: ['easy', 'medium', 'hard'],
              include_blank: false

      f.input :points,
              hint: 'Points awarded for solving (default: 100)'
    end

    f.inputs 'Media URLs' do
      # ❌ background_image_url removed — comes from anime.image_url
      # ❌ character_image_url removed — comes from character.image_url
      f.input :video_url, label: 'Video URL (optional)'
      f.input :video_thumbnail_url, label: 'Video Thumbnail URL (optional)'
      f.input :video_duration, label: 'Video Duration (seconds)'
    end

    f.inputs 'Scheduling' do
      f.input :featured_date,
              label: 'Daily Puzzle Date (optional)',
              hint: 'Leave blank for regular puzzles, set date for daily featured puzzle'
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :solution
      row :encrypted_text
      row :anime
      row :character
      row :author
      row 'Character Image' do |puzzle|
        image_tag(puzzle.character.image_url, height: 80) if puzzle.character&.image_url.present?
      end
      row 'Anime Cover' do |puzzle|
        image_tag(puzzle.anime.image_url, height: 80) if puzzle.anime&.image_url.present?
      end
      row :artwork
      row :topic
      row :difficulty
      row :points

      row 'Cipher Preview' do |puzzle|
        table do
          thead { tr { th 'Original'; th 'Encrypted' } }
          tbody { tr { td puzzle.solution; td puzzle.encrypted_text } }
        end
      end

      row 'Starting Letters' do |puzzle|
        puzzle.starting_letters.map { |sl| "#{sl['actual']} → #{sl['encrypted']}" }.join(', ')
      end

      row 'Cipher Mapping' do |puzzle|
        table do
          thead { tr { th 'Letter'; th 'Encrypts to' } }
          tbody do
            puzzle.cipher_mapping.each do |original, encrypted|
              tr { td original; td encrypted }
            end
          end
        end
      end

      row 'Generated Hints' do |puzzle|
        ul do
          puzzle.hints.each do |hint|
            li "#{hint['type']}: #{hint['letter'] || hint['word']} (cost: #{hint['cost']})"
          end
        end
      end

      row :video_url
      row :featured_date
      row :created_at
      row :updated_at
    end
  end
end

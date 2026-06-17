# app/admin/puzzles.rb
ActiveAdmin.register Puzzle do

  controller do
    def scoped_collection
      super.includes(:work, :character, :author)
    end
  end

  permit_params :solution, :topic, :difficulty, :artwork, :points,
                :work_id, :character_id, :author_id,
                :video_url, :video_thumbnail_url, :video_duration,
                :featured_date,
                :solution_en, :solution_fr, :solution_es, :solution_de, :solution_it, :solution_pt

  index do
    selectable_column
    id_column
    column :solution do |puzzle|
      truncate(puzzle.solution_for('en'), length: 50)
    end
    column "Languages" do |puzzle|
      puzzle.available_locales.join(', ').upcase
    end
    column :work
    column :character
    column :difficulty
    column :featured_date
    column :created_at
    actions
  end

  filter :difficulty
  filter :topic
  filter :featured_date
  filter :created_at
  filter :default_locale

  form do |f|
    f.inputs 'Puzzle Content' do
      f.input :solution_en,
              label: 'Quote Text (English)',
              hint: 'Enter the original work quote in English (cipher will be auto-generated)',
              input_html: { rows: 3, value: f.object.solution_for('en') }

      f.input :solution_fr,
              label: 'Quote Text (French)',
              hint: 'Optional: Enter the French translation (no accents, uppercase)',
              input_html: { rows: 3, value: f.object.solution_for('fr') }

      f.input :solution_es,
              label: 'Quote Text (Spanish)',
              hint: 'Optional: Enter the Spanish translation',
              input_html: { rows: 3, value: f.object.solution_for('es') }

      f.input :work,
              label: 'Work Source',
              as: :select,
              collection: Work.all.order(:title).map { |w| [w.title, w.id] },
              include_blank: 'Select work...'

      f.input :character,
              label: 'Character (optional)',
              as: :select,
              collection: Character.includes(:work).order(:name).map { |c| ["#{c.name} (#{c.work.title})", c.id] },
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

  controller do
    def create
      @puzzle = Puzzle.new(puzzle_params)

      solutions_hash = {}
      solutions_hash['en'] = params[:puzzle][:solution_en].strip.upcase if params[:puzzle][:solution_en].present?
      solutions_hash['fr'] = params[:puzzle][:solution_fr].strip.upcase if params[:puzzle][:solution_fr].present?
      solutions_hash['es'] = params[:puzzle][:solution_es].strip.upcase if params[:puzzle][:solution_es].present?
      solutions_hash['de'] = params[:puzzle][:solution_de].strip.upcase if params[:puzzle][:solution_de].present?
      solutions_hash['it'] = params[:puzzle][:solution_it].strip.upcase if params[:puzzle][:solution_it].present?
      solutions_hash['pt'] = params[:puzzle][:solution_pt].strip.upcase if params[:puzzle][:solution_pt].present?

      @puzzle.solutions = solutions_hash
      @puzzle.default_locale = 'en'

      if @puzzle.save
        redirect_to admin_puzzle_path(@puzzle), notice: 'Puzzle was successfully created.'
      else
        render :new
      end
    end

    def update
      @puzzle = Puzzle.find(params[:id])

      solutions_hash = @puzzle.solutions || {}
      solutions_hash['en'] = params[:puzzle][:solution_en].strip.upcase if params[:puzzle][:solution_en].present?
      solutions_hash['fr'] = params[:puzzle][:solution_fr].strip.upcase if params[:puzzle][:solution_fr].present?
      solutions_hash['es'] = params[:puzzle][:solution_es].strip.upcase if params[:puzzle][:solution_es].present?
      solutions_hash['de'] = params[:puzzle][:solution_de].strip.upcase if params[:puzzle][:solution_de].present?
      solutions_hash['it'] = params[:puzzle][:solution_it].strip.upcase if params[:puzzle][:solution_it].present?
      solutions_hash['pt'] = params[:puzzle][:solution_pt].strip.upcase if params[:puzzle][:solution_pt].present?

      @puzzle.solutions = solutions_hash
      @puzzle.assign_attributes(puzzle_params)

      @puzzle.send(:generate_all_ciphers)
      @puzzle.send(:generate_all_hints)

      if @puzzle.save
        redirect_to admin_puzzle_path(@puzzle), notice: 'Puzzle was successfully updated.'
      else
        render :edit
      end
    end

    private

    def puzzle_params
      params.require(:puzzle).permit(
        :topic, :difficulty, :artwork, :points,
        :work_id, :character_id, :author_id,
        :video_url, :video_thumbnail_url, :video_duration,
        :featured_date
      )
    end
  end

  show do
    attributes_table do
      row :id
      row "English Solution" do |puzzle|
        puzzle.solution_for('en')
      end
      row "French Solution" do |puzzle|
        puzzle.solution_for('fr') if puzzle.locale_available?('fr')
      end
      row "Available Languages" do |puzzle|
        puzzle.available_locales.join(', ').upcase
      end
      row :work
      row :character
      row :author
      row 'Character Image' do |puzzle|
        image_tag(puzzle.character.image_url, height: 80) if puzzle.character&.image_url.present?
      end
      row 'Work Cover' do |puzzle|
        image_tag(puzzle.work.image_url, height: 80) if puzzle.work&.image_url.present?
      end
      row :artwork
      row :topic
      row :difficulty
      row :points

      panel "Cipher Previews (All Languages)" do
        puzzle.available_locales.each do |locale|
          h4 "#{locale.upcase} Version"
          table do
            thead { tr { th 'Original'; th 'Encrypted' } }
            tbody { tr { td puzzle.solution_for(locale); td puzzle.encrypted_text_for(locale) } }
          end
        end
      end

      row 'Starting Letters (EN)' do |puzzle|
        puzzle.starting_letters_for('en').map { |sl| "#{sl['actual']} → #{sl['encrypted']}" }.join(', ')
      end

      row 'Hints (EN)' do |puzzle|
        ul do
          puzzle.hints_for('en').each do |hint|
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

# app/admin/characters.rb
ActiveAdmin.register Character do
  permit_params :name, :name_original, :bio, :voice_actor, :voice_actor_japanese, :work_id, :image_url,
                :name_en, :name_fr, :name_es, :name_de, :name_it, :name_pt

  remove_filter :puzzles

  def self.ransackable_attributes(auth_object = nil)
    %w[name voice_actor]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[work]
  end

  index do
    selectable_column
    id_column
    column :name
    column "Languages" do |character|
      character.available_locales.join(', ').upcase if character.names.present?
    end
    column :work do |character|
      link_to character.work.title, admin_work_path(character.work) if character.work
    end
    column :voice_actor
    column :puzzles do |character|
      character.puzzles.count
    end
    actions
  end

  filter :name
  filter :work
  filter :voice_actor
  filter :created_at

  form do |f|
    f.inputs "Character Details" do
      f.input :work,
              as: :select,
              collection: Work.all.order(:title).map { |w| [w.title, w.id] },
              prompt: "Select Work"

      f.input :bio, as: :text, input_html: { rows: 5 }
      f.input :voice_actor
      f.input :voice_actor_japanese
      f.input :image_url, label: 'Character Image URL'
    end

    f.inputs 'Names (Multilanguage)' do
      f.input :name_en,
              label: 'Name (English)',
              hint: 'English name (required)',
              input_html: { value: f.object.name_for('en') }

      f.input :name_fr,
              label: 'Name (French)',
              hint: 'French name (optional)',
              input_html: { value: f.object.name_for('fr') }

      f.input :name_es,
              label: 'Name (Spanish)',
              hint: 'Spanish name (optional)',
              input_html: { value: f.object.name_for('es') }

      f.input :name_original,
              label: 'Name (Original)',
              hint: 'Original name in native script (optional)'
    end

    f.actions
  end

  controller do
    def create
      @character = Character.new(character_params)

      names_hash = {}
      names_hash['en'] = params[:character][:name_en].strip if params[:character][:name_en].present?
      names_hash['fr'] = params[:character][:name_fr].strip if params[:character][:name_fr].present?
      names_hash['es'] = params[:character][:name_es].strip if params[:character][:name_es].present?

      @character.names = names_hash
      @character.name = names_hash['en'] || names_hash.values.first

      if @character.save
        redirect_to admin_character_path(@character), notice: 'Character was successfully created.'
      else
        render :new
      end
    end

    def update
      @character = Character.find(params[:id])

      names_hash = @character.names || {}
      names_hash['en'] = params[:character][:name_en].strip if params[:character][:name_en].present?
      names_hash['fr'] = params[:character][:name_fr].strip if params[:character][:name_fr].present?
      names_hash['es'] = params[:character][:name_es].strip if params[:character][:name_es].present?

      @character.names = names_hash
      @character.name = names_hash['en'] || names_hash.values.first
      @character.assign_attributes(character_params)

      if @character.save
        redirect_to admin_character_path(@character), notice: 'Character was successfully updated.'
      else
        render :edit
      end
    end

    private

    def character_params
      params.require(:character).permit(:work_id, :bio, :voice_actor, :voice_actor_japanese, :image_url, :name_original)
    end
  end

  show do
    attributes_table do
      row :id

      panel "Names (All Languages)" do
        if character.names.present?
          table do
            thead { tr { th 'Language'; th 'Name' } }
            tbody do
              character.names.each do |locale, name|
                tr { td locale.upcase; td name }
              end
            end
          end
        else
          para "No multilanguage names set. Using legacy name: #{character.name}"
        end
      end

      row :work do |character|
        link_to character.work.title, admin_work_path(character.work) if character.work
      end
      row :bio
      row :voice_actor
      row :voice_actor_japanese
      row 'Character Image' do |character|
        image_tag(character.image_url, height: 150) if character.image_url.present?
      end
      row :created_at
      row :updated_at
    end

    panel "Puzzles (#{character.puzzles.count})" do
      table_for character.puzzles do
        column :id do |puzzle|
          link_to puzzle.id, admin_puzzle_path(puzzle)
        end
        column :solution do |puzzle|
          truncate(puzzle.solution_for('en'), length: 50)
        end
        column :difficulty
        column :points
      end
    end
  end
end

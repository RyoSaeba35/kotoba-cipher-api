# app/admin/animes.rb
ActiveAdmin.register Anime do
  permit_params :title, :title_japanese, :creator, :studio, :year, :anime_type, :image_url,
                :title_en, :title_fr, :title_es, :title_de, :title_it, :title_pt

  def self.ransackable_attributes(auth_object = nil)
    %w[title creator studio year anime_type]
  end

  index do
    selectable_column
    id_column
    column :title
    column "Languages" do |anime|
      anime.available_locales.join(', ').upcase if anime.titles.present?
    end
    column :creator
    column :studio
    column :year
    column :anime_type
    column :puzzles do |anime|
      anime.puzzles.count
    end
    actions
  end

  filter :title
  filter :creator
  filter :studio
  filter :anime_type
  filter :year

  form do |f|
    f.inputs 'Basic Information' do
      f.input :creator
      f.input :studio
      f.input :year
      f.input :anime_type, as: :select, collection: ['anime', 'manga']
      f.input :image_url, label: 'Cover Image URL'
    end

    f.inputs 'Titles (Multilanguage)' do
      f.input :title_en,
              label: 'Title (English)',
              hint: 'English title (required)',
              input_html: { value: f.object.title_for('en') }

      f.input :title_fr,
              label: 'Title (French)',
              hint: 'French title (optional)',
              input_html: { value: f.object.title_for('fr') }

      f.input :title_es,
              label: 'Title (Spanish)',
              hint: 'Spanish title (optional)',
              input_html: { value: f.object.title_for('es') }

      f.input :title_japanese,
              label: 'Title (Japanese)',
              hint: 'Original Japanese title (optional)'
    end

    f.actions
  end

  controller do
    def create
      @anime = Anime.new(anime_params)

      # Build titles hash from form inputs
      titles_hash = {}
      titles_hash['en'] = params[:anime][:title_en].strip if params[:anime][:title_en].present?
      titles_hash['fr'] = params[:anime][:title_fr].strip if params[:anime][:title_fr].present?
      titles_hash['es'] = params[:anime][:title_es].strip if params[:anime][:title_es].present?
      titles_hash['ja'] = params[:anime][:title_japanese].strip if params[:anime][:title_japanese].present?

      @anime.titles = titles_hash
      @anime.title = titles_hash['en'] || titles_hash.values.first # Set old column for backwards compat

      if @anime.save
        redirect_to admin_anime_path(@anime), notice: 'Anime was successfully created.'
      else
        render :new
      end
    end

    def update
      @anime = Anime.find(params[:id])

      # Build titles hash from form inputs
      titles_hash = @anime.titles || {}
      titles_hash['en'] = params[:anime][:title_en].strip if params[:anime][:title_en].present?
      titles_hash['fr'] = params[:anime][:title_fr].strip if params[:anime][:title_fr].present?
      titles_hash['es'] = params[:anime][:title_es].strip if params[:anime][:title_es].present?
      titles_hash['ja'] = params[:anime][:title_japanese].strip if params[:anime][:title_japanese].present?

      @anime.titles = titles_hash
      @anime.title = titles_hash['en'] || titles_hash.values.first
      @anime.assign_attributes(anime_params)

      if @anime.save
        redirect_to admin_anime_path(@anime), notice: 'Anime was successfully updated.'
      else
        render :edit
      end
    end

    private

    def anime_params
      params.require(:anime).permit(:creator, :studio, :year, :anime_type, :image_url, :title_japanese)
    end
  end

  show do
    attributes_table do
      row :id

      panel "Titles (All Languages)" do
        if anime.titles.present?
          table do
            thead { tr { th 'Language'; th 'Title' } }
            tbody do
              anime.titles.each do |locale, title|
                tr do
                  td locale.upcase
                  td title
                end
              end
            end
          end
        else
          para "No multilanguage titles set. Using legacy title: #{anime.title}"
        end
      end

      row :creator
      row :studio
      row :year
      row :anime_type
      row :image_url
      row 'Cover Image' do |anime|
        image_tag(anime.image_url, height: 150) if anime.image_url.present?
      end
      row :created_at
      row :updated_at
    end

    panel "Puzzles (#{anime.puzzles.count})" do
      table_for anime.puzzles do
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

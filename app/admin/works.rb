# app/admin/works.rb
ActiveAdmin.register Work do
  permit_params :title, :title_original, :creator, :studio, :year, :work_type, :image_url,
                :title_en, :title_fr, :title_es, :title_de, :title_it, :title_pt

  def self.ransackable_attributes(auth_object = nil)
    %w[title creator studio year work_type]
  end

  index do
    selectable_column
    id_column
    column :title
    column "Languages" do |work|
      work.available_locales.join(', ').upcase if work.titles.present?
    end
    column :creator
    column :studio
    column :year
    column :work_type
    column :puzzles do |work|
      work.puzzles.count
    end
    actions
  end

  filter :title
  filter :creator
  filter :studio
  filter :work_type
  filter :year

  form do |f|
    f.inputs 'Basic Information' do
      f.input :creator
      f.input :studio
      f.input :year
      f.input :work_type, as: :select, collection: ['anime', 'manga', 'book', 'philosophy']
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

      f.input :title_original,
              label: 'Title (Original language)',
              hint: 'Original title (Japanese, Chinese, Greek, etc.) — optional'
    end

    f.actions
  end

  controller do
    def create
      @work = Work.new(work_params)

      titles_hash = {}
      titles_hash['en'] = params[:work][:title_en].strip if params[:work][:title_en].present?
      titles_hash['fr'] = params[:work][:title_fr].strip if params[:work][:title_fr].present?
      titles_hash['es'] = params[:work][:title_es].strip if params[:work][:title_es].present?

      @work.titles = titles_hash
      @work.title = titles_hash['en'] || titles_hash.values.first

      if @work.save
        redirect_to admin_work_path(@work), notice: 'Work was successfully created.'
      else
        render :new
      end
    end

    def update
      @work = Work.find(params[:id])

      titles_hash = @work.titles || {}
      titles_hash['en'] = params[:work][:title_en].strip if params[:work][:title_en].present?
      titles_hash['fr'] = params[:work][:title_fr].strip if params[:work][:title_fr].present?
      titles_hash['es'] = params[:work][:title_es].strip if params[:work][:title_es].present?

      @work.titles = titles_hash
      @work.title = titles_hash['en'] || titles_hash.values.first
      @work.assign_attributes(work_params)

      if @work.save
        redirect_to admin_work_path(@work), notice: 'Work was successfully updated.'
      else
        render :edit
      end
    end

    private

    def work_params
      params.require(:work).permit(:creator, :studio, :year, :work_type, :image_url, :title_original)
    end
  end

  show do
    attributes_table do
      row :id

      panel "Titles (All Languages)" do
        if work.titles.present?
          table do
            thead { tr { th 'Language'; th 'Title' } }
            tbody do
              work.titles.each do |locale, title|
                tr { td locale.upcase; td title }
              end
            end
          end
        else
          para "No multilanguage titles set. Using legacy title: #{work.title}"
        end
      end

      row :creator
      row :studio
      row :year
      row :work_type
      row :title_original
      row :image_url
      row 'Cover Image' do |work|
        image_tag(work.image_url, height: 150) if work.image_url.present?
      end
      row :created_at
      row :updated_at
    end

    panel "Puzzles (#{work.puzzles.count})" do
      table_for work.puzzles do
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

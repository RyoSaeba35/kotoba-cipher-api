# app/admin/authors.rb
ActiveAdmin.register Author do
  permit_params :name, :bio, :image_url, :wikipedia_url,
                :bio_en, :bio_fr, :bio_es, :bio_de, :bio_it, :bio_pt

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end

  remove_filter :puzzles

  index do
    selectable_column
    id_column
    column :name
    column "Languages" do |author|
      author.available_locales.join(', ').upcase if author.bios.present?
    end
    column :puzzles do |author|
      author.puzzles.count
    end
    column :created_at
    actions
  end

  form do |f|
    f.inputs "Author Details" do
      f.input :name
      f.input :image_url
      f.input :wikipedia_url
    end

    f.inputs 'Bios (Multilanguage)' do
      f.input :bio_en,
              label: 'Bio (English)',
              as: :text,
              hint: 'English biography (required)',
              input_html: { rows: 5, value: f.object.bio_for('en') }

      f.input :bio_fr,
              label: 'Bio (French)',
              as: :text,
              hint: 'French biography (optional)',
              input_html: { rows: 5, value: f.object.bio_for('fr') }

      f.input :bio_es,
              label: 'Bio (Spanish)',
              as: :text,
              hint: 'Spanish biography (optional)',
              input_html: { rows: 5, value: f.object.bio_for('es') }
    end

    f.actions
  end

  controller do
    def create
      @author = Author.new(author_params)

      # Build bios hash from form inputs
      bios_hash = {}
      bios_hash['en'] = params[:author][:bio_en].strip if params[:author][:bio_en].present?
      bios_hash['fr'] = params[:author][:bio_fr].strip if params[:author][:bio_fr].present?
      bios_hash['es'] = params[:author][:bio_es].strip if params[:author][:bio_es].present?

      @author.bios = bios_hash
      @author.bio = bios_hash['en'] || bios_hash.values.first # Set old column for backwards compat

      if @author.save
        redirect_to admin_author_path(@author), notice: 'Author was successfully created.'
      else
        render :new
      end
    end

    def update
      @author = Author.find(params[:id])

      # Build bios hash from form inputs
      bios_hash = @author.bios || {}
      bios_hash['en'] = params[:author][:bio_en].strip if params[:author][:bio_en].present?
      bios_hash['fr'] = params[:author][:bio_fr].strip if params[:author][:bio_fr].present?
      bios_hash['es'] = params[:author][:bio_es].strip if params[:author][:bio_es].present?

      @author.bios = bios_hash
      @author.bio = bios_hash['en'] || bios_hash.values.first
      @author.assign_attributes(author_params)

      if @author.save
        redirect_to admin_author_path(@author), notice: 'Author was successfully updated.'
      else
        render :edit
      end
    end

    private

    def author_params
      params.require(:author).permit(:name, :image_url, :wikipedia_url)
    end
  end

  show do
    attributes_table do
      row :id
      row :name

      panel "Bios (All Languages)" do
        if author.bios.present?
          table do
            thead { tr { th 'Language'; th 'Bio' } }
            tbody do
              author.bios.each do |locale, bio|
                tr do
                  td locale.upcase
                  td truncate(bio, length: 200)
                end
              end
            end
          end
        else
          para "No multilanguage bios set. Using legacy bio: #{truncate(author.bio, length: 200)}"
        end
      end

      row 'Author Image' do |author|
        image_tag(author.image_url, height: 150) if author.image_url.present?
      end
      row :wikipedia_url
      row :created_at
      row :updated_at
    end

    panel "Puzzles (#{author.puzzles.count})" do
      table_for author.puzzles do
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

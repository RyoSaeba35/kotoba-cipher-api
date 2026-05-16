ActiveAdmin.register Character do
  permit_params :name, :name_japanese, :bio, :voice_actor, :voice_actor_japanese, :anime_id, :image_url

  remove_filter :puzzles

  def self.ransackable_attributes(auth_object = nil)
    %w[name voice_actor]
  end
  def self.ransackable_associations(auth_object = nil)
    %w[anime]
  end

  index do
    selectable_column
    id_column
    column :name
    column :name_japanese
    column :anime do |character|
      link_to character.anime.title, admin_anime_path(character.anime) if character.anime
    end
    column :voice_actor
    column :puzzles do |character|
      character.puzzles.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :anime
  filter :voice_actor
  filter :created_at

  show do
    attributes_table do
      row :name
      row :name_japanese
      row :anime do |character|
        link_to character.anime.title, admin_anime_path(character.anime) if character.anime
      end
      row :bio
      row :voice_actor
      row :voice_actor_japanese
      row :image_url  # ← added
      row :created_at
      row :updated_at
    end

    panel "Puzzles" do
      table_for character.puzzles do
        column :id do |puzzle|
          link_to puzzle.id, admin_puzzle_path(puzzle)
        end
        column :solution
        column :difficulty
        column :points
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Character Details" do
      f.input :anime,
              as: :select,
              collection: Anime.all.map { |a| [a.title, a.id] },
              prompt: "Select Anime"
      f.input :name
      f.input :name_japanese
      f.input :bio, as: :text, input_html: { rows: 5 }
      f.input :voice_actor
      f.input :voice_actor_japanese
      f.input :image_url, label: 'Character Image URL'  # ← added
    end
    f.actions
  end
end

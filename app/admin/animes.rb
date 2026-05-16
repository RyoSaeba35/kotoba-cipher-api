ActiveAdmin.register Anime do
  permit_params :title, :title_japanese, :creator, :studio, :year, :anime_type, :image_url

  def self.ransackable_attributes(auth_object = nil)
    %w[title creator studio year anime_type]
  end

  index do
    selectable_column
    id_column
    column :title
    column :creator
    column :studio
    column :year
    column :anime_type
    column :image_url
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
    f.inputs do
      f.input :title
      f.input :title_japanese, label: 'Japanese Title'
      f.input :creator
      f.input :studio
      f.input :year
      f.input :anime_type, as: :select, collection: ['anime', 'manga']
      f.input :image_url, label: 'Cover Image URL'
    end
    f.actions
  end
end

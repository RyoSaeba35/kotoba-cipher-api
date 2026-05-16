# app/admin/authors.rb
ActiveAdmin.register Author do
  permit_params :name, :bio, :image_url, :wikipedia_url

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end

  # Remove puzzles filter - can't filter by has_many relationship
  remove_filter :puzzles

  index do
    selectable_column
    id_column
    column :name
    column :bio
    column :puzzles do |author|
      author.puzzles.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :bio
      row :image_url
      row :wikipedia_url
      row :created_at
      row :updated_at
    end

    panel "Puzzles" do
      table_for author.puzzles do
        column :id
        column :solution
        column :difficulty
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Author Details" do
      f.input :name
      f.input :bio, as: :text
      f.input :image_url
      f.input :wikipedia_url
    end
    f.actions
  end
end

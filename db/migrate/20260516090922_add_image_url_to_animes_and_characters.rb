class AddImageUrlToAnimesAndCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :animes, :image_url, :string
    add_column :characters, :image_url, :string
  end
end

class RemoveImageUrlsFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    remove_column :puzzles, :background_image_url, :string
    remove_column :puzzles, :character_image_url, :string
  end
end

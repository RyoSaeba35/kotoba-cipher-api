class RenameAnimesToWorks < ActiveRecord::Migration[8.1]
  def change
    # 1. Rename table
    rename_table :animes, :works

    # 2. Rename columns on works
    rename_column :works, :title_japanese, :title_original
    rename_column :works, :anime_type, :work_type

    # 3. Rename foreign key + column on characters
    rename_column :characters, :anime_id, :work_id
    rename_column :characters, :name_japanese, :name_original

    # 4. Rename foreign key + column on puzzles
    rename_column :puzzles, :anime_id, :work_id
  end
end

class CreateAnimes < ActiveRecord::Migration[8.1]
  def change
    create_table :animes do |t|
      t.string :title
      t.string :title_japanese
      t.string :creator
      t.string :studio
      t.integer :year
      t.string :anime_type

      t.timestamps
    end
  end
end

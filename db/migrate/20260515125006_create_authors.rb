class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name
      t.text :bio
      t.string :image_url
      t.string :wikipedia_url

      t.timestamps
    end
  end
end

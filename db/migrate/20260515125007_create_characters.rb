class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string :name
      t.string :name_japanese
      t.text :bio
      t.string :voice_actor
      t.string :voice_actor_japanese
      t.references :anime, null: false, foreign_key: true

      t.timestamps
    end
  end
end

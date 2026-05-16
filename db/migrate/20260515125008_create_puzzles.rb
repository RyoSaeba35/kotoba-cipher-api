class CreatePuzzles < ActiveRecord::Migration[8.1]
  def change
    create_table :puzzles do |t|
      # Core content
      t.text :solution, null: false
      t.text :encrypted_text
      t.string :topic
      t.string :difficulty, default: 'medium'
      t.string :artwork  # Anime/manga title for the artwork

      # Cipher data (stored as JSON)
      t.jsonb :cipher_mapping, default: {}
      t.jsonb :starting_letters, default: []
      t.jsonb :hints, default: []

      # References
      t.references :anime, null: false, foreign_key: true
      t.references :character, foreign_key: true
      t.references :author, foreign_key: true

      # Media URLs
      t.string :background_image_url
      t.string :character_image_url
      t.string :video_url
      t.string :video_thumbnail_url
      t.integer :video_duration

      # Game settings
      t.integer :points, default: 100
      t.integer :time_limit
      t.date :featured_date

      t.timestamps
    end

    add_index :puzzles, :difficulty
    add_index :puzzles, :featured_date
    add_index :puzzles, :created_at
  end
end

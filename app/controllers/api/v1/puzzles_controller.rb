# app/controllers/api/v1/puzzles_controller.rb
module Api
  module V1
    class PuzzlesController < ApplicationController
      # GET /api/v1/puzzles
      def index
        @puzzles = Puzzle.includes(:anime, :character, :author)
                         .recent
                         .limit(25)

        render json: @puzzles.map { |p| puzzle_json(p) }
      end

      # GET /api/v1/puzzles/:id
      def show
        @puzzle = Puzzle.includes(:anime, :character, :author).find(params[:id])
        render json: puzzle_json(@puzzle)
      end

      # GET /api/v1/puzzles/daily
      def daily
        @puzzle = Puzzle.includes(:anime, :character, :author)
                        .where(featured_date: Date.today)
                        .first

        if @puzzle
          render json: puzzle_json(@puzzle)
        else
          render json: { error: 'No daily puzzle available' }, status: :not_found
        end
      end

      # GET /api/v1/puzzles/bundle
      def bundle
        # Cap limit to prevent abuse (max 25 per request)
        limit = [params[:limit].to_i.positive? ? params[:limit].to_i : 25, 25].min

        puzzles = Puzzle.includes(:anime, :character, :author).order(:id)
        puzzles = puzzles.where('id > ?', params[:after_id].to_i) if params[:after_id].present?

        total_remaining = puzzles.count           # how many left after after_id
        page            = puzzles.limit(limit)    # the actual batch to return

        render json: {
          puzzles:  page.map { |p| puzzle_json(p) },
          meta: {
            count:        page.size,             # how many returned in this batch
            has_more:     total_remaining > limit, # ← Flutter knows to fetch again
            next_after_id: page.last&.id,        # ← cursor for next request
            total_available: Puzzle.count        # total puzzles in DB
          }
        }
      end

      private

      def puzzle_json(puzzle)
        {
          puzzle_id: puzzle.id,
          date: puzzle.featured_date,
          difficulty: puzzle.difficulty,

          encrypted_text: puzzle.encrypted_text,
          solution: nil,  # ✅ Never send solution to frontend!
          topic: puzzle.topic,

          character: puzzle.character&.name,
          character_japanese: puzzle.character&.name_japanese,
          artwork: puzzle.artwork.presence || puzzle.anime&.title,
          anime_title: puzzle.anime&.title,
          anime_japanese: puzzle.anime&.title_japanese,

          author: puzzle.author ? {
            name: puzzle.author.name,
            bio: puzzle.author.bio,
            image_url: puzzle.author.image_url,
            wikipedia_url: puzzle.author.wikipedia_url
          } : nil,

          media: {
            background_image: puzzle.anime&.image_url || '',       # ← from anime
            character_image:  puzzle.character&.image_url || '',   # ← from character
            video: {
              url:      puzzle.video_url || '',
              thumbnail: puzzle.video_thumbnail_url || '',
              duration:  puzzle.video_duration
            }
          },

          cipher_mapping: puzzle.cipher_mapping,  # ✅ REQUIRED for offline validation!

          starting_letters: puzzle.starting_letters,

          hints: puzzle.hints,

          points: puzzle.points,
          time_limit: puzzle.time_limit,
          created_at: puzzle.created_at
        }
      end
    end
  end
end

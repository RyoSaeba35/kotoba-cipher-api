# app/controllers/api/v1/puzzles_controller.rb
module Api
  module V1
    class PuzzlesController < ApplicationController
      # GET /api/v1/puzzles?locale=fr
      def index
        locale = params[:locale] || 'en'

        @puzzles = Puzzle.includes(:anime, :character, :author)
                         .recent
                         .limit(25)

        # ✅ Return all puzzles with automatic fallback
        render json: @puzzles.map { |p| puzzle_json(p, locale) }
      end

      # GET /api/v1/puzzles/:id?locale=fr
      def show
        locale = params[:locale] || 'en'
        @puzzle = Puzzle.includes(:anime, :character, :author).find(params[:id])

        # ✅ No error - automatic fallback to available locale
        render json: puzzle_json(@puzzle, locale)
      end

      # GET /api/v1/puzzles/daily?locale=fr
      def daily
        locale = params[:locale] || 'en'

        @puzzle = Puzzle.includes(:anime, :character, :author)
                        .where(featured_date: Date.today)
                        .first

        if @puzzle
          # ✅ Return with automatic fallback
          render json: puzzle_json(@puzzle, locale)
        else
          render json: { error: 'No daily puzzle available' }, status: :not_found
        end
      end

      # GET /api/v1/puzzles/bundle?locale=fr
      # GET /api/v1/puzzles/bundle?locale=all (returns all languages)
      def bundle
        locale = params[:locale] || 'en'
        limit = [params[:limit].to_i.positive? ? params[:limit].to_i : 25, 25].min

        puzzles = Puzzle.includes(:anime, :character, :author).order(:id)
        puzzles = puzzles.where('id > ?', params[:after_id].to_i) if params[:after_id].present?

        total_remaining = puzzles.count
        page = puzzles.limit(limit)

        render json: {
          puzzles: page.map { |p| puzzle_json(p, locale) },
          meta: {
            count: page.size,
            has_more: total_remaining > limit,
            next_after_id: page.last&.id,
            total_available: Puzzle.count,
            requested_locale: locale  # ✅ What user asked for
          }
        }
      end

      private

      def puzzle_json(puzzle, locale = 'en')
        if locale == 'all'
          puzzle_json_all_locales(puzzle)
        else
          puzzle_json_single_locale(puzzle, locale)
        end
      end

      def puzzle_json_single_locale(puzzle, locale)
        # ✅ Determine actual locale used (with fallback)
        actual_locale = puzzle.locale_available?(locale) ? locale : (puzzle.locale_available?('en') ? 'en' : puzzle.available_locales.first)

        {
          puzzle_id: puzzle.id,
          date: puzzle.featured_date,
          difficulty: puzzle.difficulty,

          # ✅ Show what was requested vs what was returned
          requested_locale: locale,
          actual_locale: actual_locale,
          available_locales: puzzle.available_locales,

          encrypted_text: puzzle.encrypted_text_for(locale),
          solution: nil,
          topic: puzzle.topic,

          character: puzzle.character&.name_for(locale),
          character_japanese: puzzle.character&.name_japanese,
          artwork: puzzle.artwork.presence || puzzle.anime&.title_for(locale),
          anime_title: puzzle.anime&.title_for(locale),
          anime_japanese: puzzle.anime&.title_japanese,

          author: puzzle.author ? {
            name: puzzle.author.name,
            bio: puzzle.author.bio_for(locale),
            image_url: puzzle.author.image_url,
            wikipedia_url: puzzle.author.wikipedia_url
          } : nil,

          media: {
            background_image: puzzle.anime&.image_url || '',
            character_image: puzzle.character&.image_url || '',
            video: {
              url: puzzle.video_url || '',
              thumbnail: puzzle.video_thumbnail_url || '',
              duration: puzzle.video_duration
            }
          },

          cipher_mapping: puzzle.cipher_mapping_for(locale),
          starting_letters: puzzle.starting_letters_for(locale),
          hints: puzzle.hints_for(locale),

          points: puzzle.points,
          time_limit: puzzle.time_limit,
          created_at: puzzle.created_at
        }
      end

      def puzzle_json_all_locales(puzzle)
        {
          puzzle_id: puzzle.id,
          date: puzzle.featured_date,
          difficulty: puzzle.difficulty,
          available_locales: puzzle.available_locales,

          # ✅ All languages - NO solutions included!
          encrypted_texts: puzzle.encrypted_texts,
          cipher_mappings: puzzle.cipher_mappings_i18n,
          starting_letters: puzzle.starting_letters_i18n,
          hints: puzzle.hints_i18n,

          topic: puzzle.topic,

          character_names: puzzle.character&.names || {},
          anime_titles: puzzle.anime&.titles || {},

          author: puzzle.author ? {
            name: puzzle.author.name,
            bios: puzzle.author.bios || {},
            image_url: puzzle.author.image_url,
            wikipedia_url: puzzle.author.wikipedia_url
          } : nil,

          media: {
            background_image: puzzle.anime&.image_url || '',
            character_image: puzzle.character&.image_url || '',
            video: {
              url: puzzle.video_url || '',
              thumbnail: puzzle.video_thumbnail_url || '',
              duration: puzzle.video_duration
            }
          },

          points: puzzle.points,
          time_limit: puzzle.time_limit,
          created_at: puzzle.created_at
        }
      end
    end
  end
end

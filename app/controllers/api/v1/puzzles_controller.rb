# app/controllers/api/v1/puzzles_controller.rb
module Api
  module V1
    class PuzzlesController < ApplicationController
      def index
        locale = params[:locale] || 'en'

        @puzzles = Puzzle.includes(:work, :character, :author)
                         .recent
                         .limit(25)

        render json: @puzzles.map { |p| puzzle_json(p, locale) }
      end

      def show
        locale = params[:locale] || 'en'
        @puzzle = Puzzle.includes(:work, :character, :author).find(params[:id])

        render json: puzzle_json(@puzzle, locale)
      end

      def daily
        today = begin
          params[:date].present? ? Date.parse(params[:date]) : Date.current
        rescue ArgumentError
          Date.current
        end

        pool = Puzzle.includes(:work, :character, :author)
                    .order(:id)
                    .to_a

        if pool.empty?
          render json: { error: 'No puzzles available' }, status: :not_found
          return
        end

        epoch        = Date.new(2026, 1, 1)
        day_index    = (today - epoch).to_i
        cycle_number = day_index / pool.size
        position     = day_index % pool.size
        shuffled     = pool.shuffle(random: Random.new(cycle_number))
        puzzle       = shuffled[position]

        locale = params[:locale] || 'en'

        render json: {
          puzzle:     puzzle_json(puzzle, locale),
          daily_meta: {
            date:       today.iso8601,
            expires_at: Time.current.end_of_day.utc.iso8601,
            cycle:      cycle_number + 1,
            pool_size:  pool.size,
          }
        }
      end

      def bundle
        locale = params[:locale] || 'en'
        limit = [params[:limit].to_i.positive? ? params[:limit].to_i : 25, 25].min

        puzzles = Puzzle.includes(:work, :character, :author).order(:id)
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
            requested_locale: locale
          }
        }
      end

      def sync
        updated_since = begin
          Time.parse(params[:updated_since])
        rescue ArgumentError, TypeError
          1.week.ago
        end

        puzzles = Puzzle.includes(:work, :character, :author)
                        .where('puzzles.updated_at > ?', updated_since)
                        .order('puzzles.updated_at')

        render json: {
          puzzles: puzzles.map { |p| puzzle_json(p, 'all') },
          meta: {
            count: puzzles.size,
            synced_at: Time.now.utc.iso8601,
            last_updated_at: puzzles.any? ? puzzles.maximum(:updated_at)&.iso8601 : nil
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
        actual_locale = puzzle.locale_available?(locale) ? locale : (puzzle.locale_available?('en') ? 'en' : puzzle.available_locales.first)

        {
          puzzle_id: puzzle.id,
          date: puzzle.featured_date,
          difficulty: puzzle.difficulty,

          requested_locale: locale,
          actual_locale: actual_locale,
          available_locales: puzzle.available_locales,

          encrypted_text: puzzle.encrypted_text_for(locale),
          solution: nil,
          topic: puzzle.topic,

          character: puzzle.character&.name_for(locale),
          character_original: puzzle.character&.name_original,
          artwork: puzzle.artwork.presence || puzzle.work&.title_for(locale),
          work_title: puzzle.work&.title_for(locale),
          work_original: puzzle.work&.title_original,

          author: puzzle.author ? {
            name: puzzle.author.name,
            bio: puzzle.author.bio_for(locale),
            image_url: puzzle.author.image_url,
            wikipedia_url: puzzle.author.wikipedia_url
          } : nil,

          media: {
            background_image: puzzle.work&.image_url || '',
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

          # All languages - NO solutions included
          encrypted_texts: puzzle.encrypted_texts,
          cipher_mappings: puzzle.cipher_mappings_i18n,
          starting_letters: puzzle.starting_letters_i18n,
          hints: puzzle.hints_i18n,

          topic: puzzle.topic,

          character_names: puzzle.character&.all_names || {},
          character_original: puzzle.character&.name_original,
          work_titles: puzzle.work&.all_titles || {},
          work_original: puzzle.work&.title_original,

          author: puzzle.author ? {
            name: puzzle.author.name,
            bios: puzzle.author.bios || {},
            image_url: puzzle.author.image_url,
            wikipedia_url: puzzle.author.wikipedia_url
          } : nil,

          media: {
            background_image: puzzle.work&.image_url || '',
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

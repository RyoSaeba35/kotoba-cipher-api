class MakePuzzleSolutionNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :puzzles, :solution, true
  end
end

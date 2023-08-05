class AddRevisionHistoryToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :revision_history, :text
  end
end

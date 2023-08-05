class AddReadingTimeToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :reading_t, :integer
  end
end

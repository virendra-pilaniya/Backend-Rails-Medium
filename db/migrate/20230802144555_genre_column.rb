class GenreColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :genre, :string
  end
end

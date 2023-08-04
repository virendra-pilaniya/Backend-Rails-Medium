class Addlikesandcommentcolumn < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :no_of_likes, :integer
    add_column :articles, :no_of_comments, :integer
    add_column :articles, :likes, :jsonb, default: [], null: false
    add_column :articles, :comments, :jsonb, default: [], null: false
  end
end
class AddIsDraftToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :is_draft, :boolean
  end
end

class AddImageToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :image, :string
    # add_reference :articles, :image, foreign_key: { to_table: :active_storage_attachments }
  end
end

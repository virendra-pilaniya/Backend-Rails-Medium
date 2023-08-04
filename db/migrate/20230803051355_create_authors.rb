class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.string :name
      t.string :genre
      t.json :article_ids, default: []
      t.timestamps
    end
  end
end

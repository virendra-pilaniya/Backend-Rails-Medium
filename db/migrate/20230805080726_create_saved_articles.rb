class CreateSavedArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :saved_articles do |t|
      t.integer :user_id
      t.integer :article_id

      t.timestamps
    end

    add_index :saved_articles, [:user_id, :article_id], unique: true
  end
end

class CreateArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.references :author, foreign_key: true
      t.string :description
      # t.timestamps :created_at
      # t.timestamps :updated_at
      t.timestamps
    end
  end
end

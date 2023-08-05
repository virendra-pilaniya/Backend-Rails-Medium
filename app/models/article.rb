class Article < ApplicationRecord
    belongs_to :author
    has_one_attached :image

    has_many :saved_articles
    has_many :users_who_saved, through: :saved_articles, source: :user
end

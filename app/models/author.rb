class Author < ApplicationRecord
    has_many :articles, dependent: :destroy
    has_one :user
    serialize :article_ids, Array
end

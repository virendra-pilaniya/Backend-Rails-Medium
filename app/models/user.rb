# app/models/user.rb
class User < ApplicationRecord
    has_secure_password

    validates :name, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }

    # Add associations as needed for your application
    belongs_to :author
    has_many :saved_articles
    has_many :saved_articles, through: :saved_articles, source: :article

    # serialize :following, Array

    def follow_user(target_user_id)
      return false if target_user_id == id # A user cannot follow themselves

      target_user = User.find_by(id: target_user_id)
      return false if target_user.nil? # Target user doesn't exist, return false to indicate failure.

      self.following_ids ||= '' # Initialize following_ids if it's nil
      followed_ids = following_ids.split(',').map(&:to_i)

      unless followed_ids.include?(target_user_id)
        followed_ids << target_user_id
        update(following_ids: followed_ids.join(','))
      end

      true # Successfully followed the target user.
    end

  end

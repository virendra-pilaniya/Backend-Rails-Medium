# app/models/user.rb
class User < ApplicationRecord
    has_secure_password
  
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }
  
    # Add associations as needed for your application
    belongs_to :author
  end
  
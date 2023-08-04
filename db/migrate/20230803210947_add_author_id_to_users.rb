# db/migrate/timestamp_add_author_id_to_users.rb
class AddAuthorIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :author_id, :integer
    add_foreign_key :users, :authors
  end
end

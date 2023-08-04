class AddFollowingIdsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :following_ids, :text
  end
end

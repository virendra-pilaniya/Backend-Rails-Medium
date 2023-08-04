class AddFollowingToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :following, :json, default: []
  end
end

class AddListToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :list, :json, default: []
  end
end

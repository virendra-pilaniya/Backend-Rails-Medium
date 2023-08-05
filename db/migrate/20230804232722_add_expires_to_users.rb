class AddExpiresToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :expires_at, :datetime
  end
end

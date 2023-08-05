class AddSubscriptionPlanToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :subscription_plan, :string, default: 'free'
    add_column :users, :remaining_posts, :integer, default: 1
  end
end

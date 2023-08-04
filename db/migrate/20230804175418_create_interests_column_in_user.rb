class CreateInterestsColumnInUser < ActiveRecord::Migration[7.0]
  def change
    create_table :interests_column_in_users do |t|

      add_column :users, :interests, :string
    end
  end
end

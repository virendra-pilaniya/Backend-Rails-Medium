class AddSpecializationsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :specializations, :string
  end
end

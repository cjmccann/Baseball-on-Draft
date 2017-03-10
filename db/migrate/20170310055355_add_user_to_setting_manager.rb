class AddUserToSettingManager < ActiveRecord::Migration
  def change
    add_column :setting_managers, :user_id, :integer
  end
end

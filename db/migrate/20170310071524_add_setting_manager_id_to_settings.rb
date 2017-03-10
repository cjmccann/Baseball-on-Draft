class AddSettingManagerIdToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :setting_manager_id, :integer
  end
end

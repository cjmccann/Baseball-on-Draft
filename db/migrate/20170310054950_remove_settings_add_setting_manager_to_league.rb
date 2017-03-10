class RemoveSettingsAddSettingManagerToLeague < ActiveRecord::Migration
  def change
    add_reference :leagues, :setting_manager, index: true
    remove_reference :leagues, :setting
  end
end

class AddSettingsToLeague < ActiveRecord::Migration
  def change
    add_column :leagues, :setting_id, :integer
  end
end

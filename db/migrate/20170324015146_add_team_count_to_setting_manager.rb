class AddTeamCountToSettingManager < ActiveRecord::Migration
  def change
    add_column :setting_managers, :num_teams, :integer
  end
end

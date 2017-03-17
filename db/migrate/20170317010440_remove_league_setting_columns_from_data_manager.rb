class RemoveLeagueSettingColumnsFromDataManager < ActiveRecord::Migration
  def change
    remove_column :data_managers, :target_stats
    remove_column :data_managers, :batter_slots
    remove_column :data_managers, :pitcher_slots
  end
end

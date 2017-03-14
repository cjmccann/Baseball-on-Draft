class ChangeStatsColumnOnPlayers < ActiveRecord::Migration
  def change
    remove_column :players, :stats
    add_column :players, :stats_string, :text
  end
end

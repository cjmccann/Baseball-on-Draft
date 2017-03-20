class AddTeamRawStatsToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :team_raw_stats, :text
  end
end

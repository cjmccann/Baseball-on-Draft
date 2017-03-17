class AddNewColumnsToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :batters, :text
    add_column :teams, :pitchers, :text
    add_column :teams, :batter_slots, :text
    add_column :teams, :pitcher_slots, :text
    add_column :teams, :team_percentiles, :text
  end
end

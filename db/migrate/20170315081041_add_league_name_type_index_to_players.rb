class AddLeagueNameTypeIndexToPlayers < ActiveRecord::Migration
  def change
    add_index :players, [:league_id, :name, :player_type]
  end
end

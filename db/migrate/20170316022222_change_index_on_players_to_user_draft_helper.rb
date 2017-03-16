class ChangeIndexOnPlayersToUserDraftHelper < ActiveRecord::Migration
  def change
    remove_index :players, [:league_id, :name, :player_type]
    add_index :players, [:draft_helper_id, :name, :player_type]
  end
end

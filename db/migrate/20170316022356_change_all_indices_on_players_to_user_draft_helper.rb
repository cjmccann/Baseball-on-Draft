class ChangeAllIndicesOnPlayersToUserDraftHelper < ActiveRecord::Migration
  def change
    remove_index :players, [:league_id, :name]
    add_index :players, [:draft_helper_id, :name]

    remove_index :players, [:league_id, :player_type]
    add_index :players, [:draft_helper_id, :player_type]

    remove_index :players, [:league_id]
    add_index :players, [:draft_helper_id]
  end
end

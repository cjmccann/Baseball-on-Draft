class GeneralizePlayersForAllUsers < ActiveRecord::Migration
  def change
    remove_column :players, :team_id
    remove_column :players, :user_id
    remove_column :players, :draft_helper_id
    remove_column :players, :league_id
    remove_column :players, :stats

    add_column :players, :static_stats, :text

    remove_index :players, [:draft_helper_id, :name, :player_type]
    remove_index :players, [:draft_helper_id, :name]
    remove_index :players, [:draft_helper_id, :player_type]
    # remove_index :players, :draft_helper_id

    add_index :players, [:name, :player_type]

    remove_column :teams, :players

    add_column :draft_helpers, :drafted_player_ids, :text
    add_column :draft_helpers, :drafted_player_ids_by_team, :text
  end
end

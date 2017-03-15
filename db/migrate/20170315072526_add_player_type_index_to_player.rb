class AddPlayerTypeIndexToPlayer < ActiveRecord::Migration
  def change
    add_index :players, [:league_id, :player_type]
  end
end

class IndexPlayersByName < ActiveRecord::Migration
  def change
    add_index :players, [:league_id, :name]
  end
end

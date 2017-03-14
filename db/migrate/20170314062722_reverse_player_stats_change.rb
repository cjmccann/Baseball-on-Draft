class ReversePlayerStatsChange < ActiveRecord::Migration
  def change
    remove_column :players, :stats_string
    add_column :players, :stats, :text
  end
end

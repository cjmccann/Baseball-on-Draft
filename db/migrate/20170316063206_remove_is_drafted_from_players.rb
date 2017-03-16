class RemoveIsDraftedFromPlayers < ActiveRecord::Migration
  def change
    remove_column :players, :is_drafted
  end
end

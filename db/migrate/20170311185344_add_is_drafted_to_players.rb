class AddIsDraftedToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :is_drafted, :boolean
  end
end

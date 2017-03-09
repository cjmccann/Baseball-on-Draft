class AddLeagueToUsers < ActiveRecord::Migration
  def change
    add_column :leagues, :user_id, :integer

    #add_reference :leagues, :user, foreign_key: true
  end
end

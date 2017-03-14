class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :position
      t.string :player_type
      t.text :stats

      t.references :team, foreign_key: true
      t.references :user, foreign_key: true
      t.references :draft_helper, foreign_key: true

      t.timestamps null: false
    end
  end
end

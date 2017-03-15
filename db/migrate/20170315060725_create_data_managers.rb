class CreateDataManagers < ActiveRecord::Migration
  def change
    create_table :data_managers do |t|
      t.references :draft_helper, foreign_key: true
      t.references :league, foreign_key: true
      t.references :user, foreign_key: true

      t.text :averages
      t.text :stddevs
      t.text :positional_adjustments
      t.text :target_stats
      t.text :batter_slots
      t.text :pitcher_slots

      t.timestamps null: false
    end
  end
end

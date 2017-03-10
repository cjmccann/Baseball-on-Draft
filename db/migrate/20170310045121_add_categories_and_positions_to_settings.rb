class AddCategoriesAndPositionsToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :batter_positions, :text
    add_column :settings, :pitcher_positions, :text
    add_column :settings, :batter_categories, :text
    add_column :settings, :pitcher_categories, :text
    remove_column :settings, :fields
  end
end

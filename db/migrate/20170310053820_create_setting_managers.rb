class CreateSettingManagers < ActiveRecord::Migration
  def change
    create_table :setting_managers do |t|

      t.references :league, foreign_key: true
      t.timestamps null: false
    end

    remove_column :settings, :batter_positions
    remove_column :settings, :pitcher_positions
    remove_column :settings, :batter_categories
    remove_column :settings, :pitcher_categories

    add_column :settings, :type, :string
    add_column :settings, :name, :string
    add_column :settings, :position_value, :integer
    add_column :settings, :category_value, :boolean
  end
end

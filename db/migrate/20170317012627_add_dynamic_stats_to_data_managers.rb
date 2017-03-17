class AddDynamicStatsToDataManagers < ActiveRecord::Migration
  def change
    add_column :data_managers, :means, :text
    add_column :data_managers, :current_zscores, :text
    add_column :data_managers, :current_percentiles, :text
    add_column :data_managers, :initial_zscores, :text
    add_column :data_managers, :initial_percentiles, :text
  end
end

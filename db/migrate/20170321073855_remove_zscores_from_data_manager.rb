class RemoveZscoresFromDataManager < ActiveRecord::Migration
  def change
    remove_column :data_managers, :current_zscores
    remove_column :data_managers, :initial_zscores
  end
end

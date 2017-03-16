class AddDataManagerForeignIdToDraftHelper < ActiveRecord::Migration
  def change
    add_foreign_key :draft_helpers, :data_managers
  end
end

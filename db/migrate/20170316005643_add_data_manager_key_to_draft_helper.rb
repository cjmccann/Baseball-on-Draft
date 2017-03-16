class AddDataManagerKeyToDraftHelper < ActiveRecord::Migration
  def change
    add_reference :draft_helpers, :data_manager
  end
end

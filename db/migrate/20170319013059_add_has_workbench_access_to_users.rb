class AddHasWorkbenchAccessToUsers < ActiveRecord::Migration
  def change
    add_column :users, :has_workbench_access, :boolean
  end
end

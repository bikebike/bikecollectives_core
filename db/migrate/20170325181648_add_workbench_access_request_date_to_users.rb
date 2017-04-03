class AddWorkbenchAccessRequestDateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :workbench_access_request_date, :datetime
  end
end

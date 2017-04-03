class AddWorkbenchAccessRequestMessageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :workbench_access_request_message, :text
  end
end

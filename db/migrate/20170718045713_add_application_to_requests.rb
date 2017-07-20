class AddApplicationToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :application, :string
  end
end

class AddResponseToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :response, :integer
  end
end

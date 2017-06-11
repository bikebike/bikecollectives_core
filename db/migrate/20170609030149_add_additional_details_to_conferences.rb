class AddAdditionalDetailsToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :additional_details, :text
  end
end

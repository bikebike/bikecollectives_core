class AddTypeToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :conferencetype, :string
  end
end

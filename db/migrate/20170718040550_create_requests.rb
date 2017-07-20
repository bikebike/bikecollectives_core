class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :request_id
      t.string :session_id
      t.json :data

      t.timestamps null: false
    end
  end
end

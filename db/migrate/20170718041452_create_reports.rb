class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :request_id
      t.string :signature
      t.string :severity
      t.string :source
      t.string :backtrace

      t.timestamps null: false
    end
  end
end

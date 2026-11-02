class CreateShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :shifts do |t|
      t.time :start_time
      t.time :end_time
      t.integer :interval_duration

      t.timestamps
    end
  end
end

class CreateShiftIntervals < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_intervals do |t|
      t.references :shift, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end

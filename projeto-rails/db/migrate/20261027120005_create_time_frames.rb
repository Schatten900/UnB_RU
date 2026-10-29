class CreateTimeFrames < ActiveRecord::Migration[7.1]
  def change
    create_table :time_frames, id: :integer do |t|
      t.references :turno, type: :integer, null: false, foreign_key: { to_table: :turnos }
      t.time :inicio, null: false
      t.time :fim, null: false
    end
  end
end

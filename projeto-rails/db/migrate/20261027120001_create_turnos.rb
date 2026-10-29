class CreateTurnos < ActiveRecord::Migration[7.1]
  def change
    create_table :turnos, id: :integer do |t|
      t.string :nome, null: false
      t.time :inicio, null: false
      t.time :fim, null: false
      t.decimal :preco, precision: 10, scale: 2, null: false
    end
  end
end

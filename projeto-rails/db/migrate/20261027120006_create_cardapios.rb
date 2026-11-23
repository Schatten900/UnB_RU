class CreateCardapios < ActiveRecord::Migration[7.1]
  def change
    create_table :cardapios, id: :integer do |t|
      t.references :turno, type: :integer, null: false, foreign_key: { to_table: :turnos }
      t.date :data, null: false
      t.string :opcao_padrao
      t.string :opcao_ovolactovegetariana
      t.string :opcao_vegetariana_estrita
    end
  end
end

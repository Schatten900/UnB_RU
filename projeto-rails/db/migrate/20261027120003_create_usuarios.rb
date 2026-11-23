class CreateUsuarios < ActiveRecord::Migration[7.1]
  def change
    create_table :usuarios, id: :string, primary_key: :matricula do |t|
      t.string :nome, null: false
      t.string :senha_hash, null: false
      t.references :turno, type: :integer, foreign_key: { to_table: :turnos }
      t.references :restaurante, type: :integer, foreign_key: { to_table: :restaurantes }
      t.string :perfil, null: false
      t.decimal :saldo, precision: 10, scale: 2, null: false, default: 0
    end
  end
end

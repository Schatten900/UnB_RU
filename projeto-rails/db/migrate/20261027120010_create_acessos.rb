class CreateAcessos < ActiveRecord::Migration[7.1]
  def change
    create_table :acessos, id: :integer do |t|
      t.string :usuario_matricula, null: false
      t.references :catraca, type: :integer, null: false, foreign_key: { to_table: :catracas }
      t.references :turno, type: :integer, null: false, foreign_key: { to_table: :turnos }
      t.references :inscricao_fastpass, type: :integer,
                                       foreign_key: { to_table: :inscricoes_fastpass }
      t.datetime :data_hora, null: false
      t.string :status, null: false
      t.datetime :passagem_em
      t.decimal :valor_debitado, precision: 10, scale: 2, null: false, default: 0

      t.index :usuario_matricula
    end

    add_foreign_key :acessos, :usuarios,
                    column: :usuario_matricula, primary_key: :matricula
  end
end

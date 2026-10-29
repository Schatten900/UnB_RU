class CreateInscricoesFastpass < ActiveRecord::Migration[7.1]
  def change
    create_table :inscricoes_fastpass, id: :integer do |t|
      t.string :usuario_matricula, null: false
      t.references :sorteio, type: :integer, null: false, foreign_key: { to_table: :sorteios }
      t.references :time_frame, type: :integer, null: false,
                                foreign_key: { to_table: :time_frames }
      t.string :resultado
      t.string :status_notificacao, null: false
      t.datetime :notificada_em

      t.index :usuario_matricula
    end

    add_foreign_key :inscricoes_fastpass, :usuarios,
                    column: :usuario_matricula, primary_key: :matricula
  end
end

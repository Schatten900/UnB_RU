class CreateNotificacoes < ActiveRecord::Migration[7.1]
  def change
    create_table :notificacoes do |t|
      t.string :usuario_matricula, null: false
      t.text :mensagem, null: false

      t.timestamps
    end

    add_index :notificacoes, :usuario_matricula
    add_foreign_key :notificacoes, :usuarios,
      column: :usuario_matricula,
      primary_key: :matricula
  end
end
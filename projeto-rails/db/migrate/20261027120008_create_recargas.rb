class CreateRecargas < ActiveRecord::Migration[7.1]
  def change
    create_table :recargas, id: :integer do |t|
      t.string :usuario_matricula, null: false
      t.datetime :data_hora, null: false
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.string :metodo, null: false
      t.string :status, null: false

      t.index :usuario_matricula
    end

    add_foreign_key :recargas, :usuarios,
                    column: :usuario_matricula, primary_key: :matricula
  end
end

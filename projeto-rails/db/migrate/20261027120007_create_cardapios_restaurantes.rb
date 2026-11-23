class CreateCardapiosRestaurantes < ActiveRecord::Migration[7.1]
  def change
    create_table :cardapios_restaurantes, id: false do |t|
      t.references :cardapio, type: :integer, null: false,
                              index: false, foreign_key: { to_table: :cardapios }
      t.references :restaurante, type: :integer, null: false,
                                 foreign_key: { to_table: :restaurantes }

      t.index [:cardapio_id, :restaurante_id], unique: true
    end
  end
end

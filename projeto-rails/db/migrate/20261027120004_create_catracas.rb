class CreateCatracas < ActiveRecord::Migration[7.1]
  def change
    create_table :catracas, id: :integer do |t|
      t.references :restaurante, type: :integer, null: false,
                                 foreign_key: { to_table: :restaurantes }
      t.integer :piso, null: false
      t.string :modo_acesso, null: false
    end
  end
end

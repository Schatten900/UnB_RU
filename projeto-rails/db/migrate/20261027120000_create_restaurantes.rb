class CreateRestaurantes < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurantes, id: :integer do |t|
      t.string :nome, null: false
    end
  end
end

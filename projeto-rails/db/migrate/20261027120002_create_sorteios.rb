class CreateSorteios < ActiveRecord::Migration[7.1]
  def change
    create_table :sorteios, id: :integer do |t|
      t.date :data, null: false
      t.string :status, null: false
    end
  end
end

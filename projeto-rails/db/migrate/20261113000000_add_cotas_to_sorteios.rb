class AddCotasToSorteios < ActiveRecord::Migration[7.1]
  def change
    add_column :sorteios, :cotas, :json, default: {}, null: false
  end
end

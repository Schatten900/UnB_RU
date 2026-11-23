class AddCodigoPixToRecargas < ActiveRecord::Migration[7.1]
  def change
    add_column :recargas, :codigo_pix, :string
  end
end

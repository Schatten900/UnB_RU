class NormalizeInscricaoFastpassResults < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE inscricoes_fastpass
      SET resultado = 'ganhou'
      WHERE resultado = 'contemplada'
    SQL

    execute <<~SQL
      UPDATE inscricoes_fastpass
      SET resultado = 'nao_ganhou'
      WHERE resultado = 'nao contemplada'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE inscricoes_fastpass
      SET resultado = 'contemplada'
      WHERE resultado = 'ganhou'
    SQL

    execute <<~SQL
      UPDATE inscricoes_fastpass
      SET resultado = 'nao contemplada'
      WHERE resultado = 'nao_ganhou'
    SQL
  end
end
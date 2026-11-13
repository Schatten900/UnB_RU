class AddUniqueIndexToAcessosInscricaoFastpass < ActiveRecord::Migration[7.1]
  def change
    add_index :acessos,
      :inscricao_fastpass_id,
      unique: true,
      where: "inscricao_fastpass_id IS NOT NULL",
      name: "index_acessos_unique_inscricao_fastpass"
  end
end
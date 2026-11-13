class LimitFastpassUniquenessToConfirmedPassages < ActiveRecord::Migration[7.1]
  def change
    remove_index :acessos, column: :inscricao_fastpass_id,
      name: "index_acessos_unique_inscricao_fastpass", unique: true,
      where: "inscricao_fastpass_id IS NOT NULL"

    # Uma inscrição pode ter várias tentativas, mas somente uma passagem.
    add_index :acessos, :inscricao_fastpass_id, unique: true,
      where: "inscricao_fastpass_id IS NOT NULL AND passagem_em IS NOT NULL",
      name: "index_acessos_unique_inscricao_fastpass"
  end
end

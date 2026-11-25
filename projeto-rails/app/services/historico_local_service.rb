class HistoricoLocalService
  class AcessoNegado < StandardError; end

  # Monta o histórico da catraca recebida para o usuário funcionário recebido.
  # Retorna relação de Acesso, vazia sem catraca, ou lança AcessoNegado; não grava no banco.
  def self.call(usuario:, catraca_id:)
    raise AcessoNegado, "Operacao restrita a funcionarios" unless usuario&.funcionario?

    return Acesso.none if catraca_id.blank?

    Acesso.where(catraca_id: catraca_id)
          .order(data_hora: :desc, id: :desc)
  end
end

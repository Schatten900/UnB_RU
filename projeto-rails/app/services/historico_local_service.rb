class HistoricoLocalService
  class AcessoNegado < StandardError; end

  def self.call(usuario:, catraca_id:)
    raise AcessoNegado, "Operacao restrita a funcionarios" unless usuario&.funcionario?

    return Acesso.none if catraca_id.blank?

    Acesso.where(catraca_id: catraca_id)
          .order(data_hora: :desc, id: :desc)
  end
end

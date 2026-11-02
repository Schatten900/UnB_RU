class HistoricoLocalService
  class AcessoNegado < StandardError; end

  def self.call(usuario:, catraca_id:, repositorio:)
    raise AcessoNegado, "Operacao restrita a funcionarios" unless usuario&.funcionario?

    return [] if catraca_id.blank?

    repositorio.listar(catraca_id: catraca_id)
  end
end

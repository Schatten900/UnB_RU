##
# Serviço responsável por localizar o restaurante selecionado
# durante a configuração do ponto de acesso.
#
class PontoConfiguracaoService
  ##
  # Localiza um restaurante a partir do identificador recebido.
  #
  # Caso o identificador esteja vazio, encerra a execução sem
  # realizar a consulta ao banco de dados.
  #
  # @param restaurante_id [Integer, String, nil] Identificador
  #   do restaurante selecionado.
  #
  # @return [Restaurante, nil] Retorna o restaurante encontrado
  #   ou nil caso o identificador esteja vazio ou não exista
  #   um restaurante correspondente.
  #
  # Efeito colateral: Realiza uma consulta ao banco de dados,
  # sem modificar seus registros.
  def self.call(restaurante_id:)
    return if restaurante_id.blank?

    Restaurante.find_by(id: restaurante_id)
  end
end

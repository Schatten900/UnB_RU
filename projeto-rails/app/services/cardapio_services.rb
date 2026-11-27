##
# Serviço responsável por localizar o cardápio correspondente
# ao turno vigente, considerando o horário e a data informados.
#
class CardapioServices
  ##
  # Localiza o turno vigente de acordo com o horário recebido
  # e busca o cardápio associado a esse turno na data atual.
  #
  # A comparação considera o fuso horário de Brasília e também
  # contempla turnos que atravessam a meia-noite.
  #
  # @param now [Time] Horário utilizado como referência para
  #   identificar o turno vigente. Por padrão, utiliza Time.current.
  #
  # @return [Cardapio, nil] Retorna o cardápio vinculado ao turno
  #   vigente na data informada ou nil caso não exista um turno
  #   correspondente ou um cardápio cadastrado.
  #
  # Efeito colateral: Realiza consultas ao banco de dados para
  # localizar os turnos e o cardápio correspondente, sem modificar
  # seus registros.
  def self.call(now: Time.current)
    horario_local = now.in_time_zone('America/Sao_Paulo')
    horario_atual = horario_local.seconds_since_midnight

    turno = Turno.order(:inicio).detect do |opcao_turno|
      inicio = opcao_turno.inicio.seconds_since_midnight
      fim = opcao_turno.fim.seconds_since_midnight

      if inicio <= fim
        horario_atual >= inicio && horario_atual < fim
      else
        horario_atual >= inicio || horario_atual < fim
      end
    end

    return nil unless turno

    # Retorna o cardápio vinculado ao turno encontrado.
    Cardapio.find_by(
      turno_id: turno.id,
      data: horario_local.to_date
    )
  end
end


##
# Executa as notificações dos usuários inscritos no FastPass.
#
# Permite notificar diretamente as inscrições de um sorteio específico
# ou localizar sorteios associados aos próximos turnos.
#
class NotificarFastPassJob < ApplicationJob
  ##
  # Define o fuso horário utilizado na identificação dos próximos turnos.
  FUSO_HORARIO = "America/Sao_Paulo"

  queue_as :default

  ##
  # Executa o processo de notificação do FastPass.
  #
  # Quando recebe um identificador de sorteio, realiza as notificações
  # correspondentes. Caso contrário, procura turnos que começam na
  # próxima hora e realiza as notificações das respectivas inscrições.
  #
  # @param sorteio_id [Integer, nil] Identificador do sorteio.
  #   Quando informado, realiza a notificação desse sorteio específico.
  # @param agora [Time] Horário utilizado como referência para localizar
  #   os próximos turnos. Por padrão, utiliza Time.current.
  #
  # @return [nil] Não retorna um valor. Executa o processo de notificação.
  #
  # @raise [ActiveRecord::RecordNotFound] Caso o identificador informado
  #   não corresponda a um sorteio cadastrado.
  #
  # Efeito colateral: Pode criar notificações no banco de dados,
  # atualizar inscrições e registrar erros no log da aplicação.
  def perform(sorteio_id = nil, agora: Time.current)
    return notificar_sorteio(sorteio_id) if sorteio_id

    notificar_proximos_turnos(agora)
  end

  private

  ##
  # Realiza as notificações das inscrições de um sorteio específico,
  # desde que ele esteja com o status "concluido".
  #
  # @param sorteio_id [Integer] Identificador do sorteio cadastrado.
  #
  # @return [nil] Não retorna um valor. Retorna antecipadamente caso
  #   o sorteio não esteja concluído.
  #
  # @raise [ActiveRecord::RecordNotFound] Caso o sorteio não exista.
  #
  # Efeito colateral: Pode criar notificações e atualizar o status
  # das inscrições associadas ao sorteio.
  def notificar_sorteio(sorteio_id)
    sorteio = Sorteio.find(sorteio_id)
    return unless sorteio.status == "concluido"

    notificar(sorteio.inscricoes_fastpass)
  end

  ##
  # Localiza os turnos que começam exatamente uma hora após o horário
  # informado e realiza as notificações das inscrições correspondentes.
  #
  # A busca considera o fuso horário de Brasília e a data do horário
  # previsto para o início do turno.
  #
  # @param agora [Time] Horário utilizado como referência para calcular
  #   o próximo período de notificação.
  #
  # @return [nil] Não retorna um valor. Encerra a execução caso não
  #   encontre um sorteio para a data prevista.
  #
  # Efeito colateral: Pode criar notificações e atualizar inscrições
  # vinculadas aos turnos encontrados.
  def notificar_proximos_turnos(agora)
    horario_local = agora.in_time_zone(FUSO_HORARIO)
    horario_alvo = horario_local + 1.hour
    data_alvo = horario_alvo.to_date
    hora_alvo = horario_alvo.strftime("%H:%M")

    # Encontra os turnos que começam daqui a uma hora.
    turnos = Turno.all.select do |turno|
      turno.inicio&.strftime("%H:%M") == hora_alvo
    end

    sorteio = Sorteio.find_by(data: data_alvo)
    return unless sorteio

    turnos.each { |turno| notificar_turno(sorteio, turno) }
  end

  ##
  # Localiza as inscrições FastPass vinculadas ao sorteio e ao turno
  # recebidos e encaminha essas inscrições para notificação.
  #
  # @param sorteio [Sorteio] Sorteio ao qual as inscrições pertencem.
  # @param turno [Turno] Turno utilizado para filtrar os períodos
  #   de inscrição (TimeFrames).
  #
  # @return [nil] Não retorna um valor.
  #
  # Efeito colateral: Pode criar notificações e atualizar os registros
  # das inscrições encontradas.
  def notificar_turno(sorteio, turno)
    time_frame_ids = TimeFrame.where(turno_id: turno.id).select(:id)
    inscricoes = InscricaoFastpass.where(
      sorteio_id: sorteio.id,
      time_frame_id: time_frame_ids
    )

    notificar(inscricoes)
  end

  ##
  # Processa uma coleção de inscrições FastPass, realizando a notificação
  # apenas das inscrições pendentes que já possuem um resultado definido.
  #
  # Cada inscrição é processada dentro de um bloqueio de registro
  # (with_lock), evitando o processamento simultâneo da mesma inscrição.
  # Caso ocorra uma falha, seu status de notificação é atualizado para
  # "falhou" e o erro é registrado no log da aplicação.
  #
  # @param inscricoes [Enumerable<InscricaoFastpass>] Coleção de inscrições
  #   que serão verificadas e processadas.
  #
  # @return [nil] Não retorna um valor.
  #
  # Efeito colateral: Pode criar notificações, atualizar o status das
  # inscrições para "entregue" ou "falhou" e registrar erros no log.
  def notificar(inscricoes)
    inscricoes.each do |inscricao|
      begin
        inscricao.with_lock do
          next unless inscricao.status_notificacao == "pendente"
          next if inscricao.resultado.blank?

          NotificacaoService.call(inscricao: inscricao)
        end
      rescue StandardError => e
        inscricao.update!(status_notificacao: "falhou")

        Rails.logger.error("Erro ao notificar inscrição #{inscricao.id}: #{e.message}")
      end
    end
  end
end


class NotificarFastPassJob < ApplicationJob
  queue_as :default

  def perform
    horario_alvo = Time.current + 1.hour
    data_alvo = horario_alvo.to_date
    hora_alvo = horario_alvo.strftime("%H:%M")

    # Encontra os turnos que começam daqui a uma hora.
    turnos = Turno.all.select do |turno|
      turno.inicio&.strftime("%H:%M") == hora_alvo
    end

    sorteio = Sorteio.find_by(data: data_alvo)
    return unless sorteio

    # Para cada turno verifica as incricoes pendentes
    turnos.each do |turno|
      time_frame_ids = TimeFrame.where(turno_id: turno.id).select(:id)

      inscricoes = InscricaoFastpass.where(
        sorteio_id: sorteio.id,
        time_frame_id: time_frame_ids
      )

      inscricoes.each do |inscricao|
        next unless inscricao.status_notificacao == "pendente"
        next if inscricao.resultado.blank?

        begin
          # O serviço cria a notificação e atualiza a inscrição.
          NotificacaoService.call(inscricao: inscricao)

        rescue StandardError => e
          inscricao.update!(status_notificacao: "falhou")

          Rails.logger.error(
            "Erro ao notificar inscrição #{inscricao.id}: #{e.message}"
          )
        end
      end
    end
  end
end

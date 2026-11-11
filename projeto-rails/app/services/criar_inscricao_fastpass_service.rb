#app/services/criar_inscricao_fastpass_service.rb
module FastPasses
  class CriarInscricaoService
    def initialize(usuario, time_frame_id)
      @usuario = usuario
      @time_frame_id = time_frame_id
    end

    def call
      time_frame = TimeFrame.find_by(id: @time_frame_id)
      raise ArgumentError, "Janela / Time-frame não encontrada" unless time_frame

      # Busca ou cria um sorteio aberto para a data de hoje (ou ativo)
      sorteio = Sorteio.find_or_create_by!(data: Date.current) do |s|
        s.status = "aberto"
      end

      @usuario.with_lock do
        # Verifica se já existe inscrição ativa para o mesmo turno neste sorteio
        existente = InscricaoFastpass.joins(:time_frame)
          .where(usuario_matricula: @usuario.matricula, sorteio_id: sorteio.id)
          .where(time_frames: { turno_id: time_frame.turno_id })
          .exists?

        if existente
          raise ArgumentError, "Você já possui uma inscrição para um horário neste mesmo turno de refeição."
        end

        inscricao = InscricaoFastpass.create!(
          usuario: @usuario,
          sorteio: sorteio,
          time_frame: time_frame,
          resultado: InscricaoFastpass::RESULTADO_GANHOU, # No mock acadêmico, ganha direto para poder testar o QR code
          status_notificacao: "entregue",
          notificada_em: Time.current
        )

        inscricao
      end
    end
  end
end


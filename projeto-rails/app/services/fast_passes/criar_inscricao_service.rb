#app/services/criar_inscricao_service.rb

module FastPasses
  class CriarInscricaoService
    def initialize(usuario, time_frame_id, restaurante_id, catraca_id)
      @usuario = usuario
      @time_frame_id = time_frame_id
      @restaurante_id = restaurante_id
      @catraca_id = catraca_id
    end

    def call
      # Busca o horário selecionado
      time_frame = TimeFrame.find_by(id: @time_frame_id)
      raise ArgumentError, "Janela / Time-frame não encontrada" unless time_frame

      # Busca o restaurante
      restaurante = Restaurante.find_by(id: @restaurante_id)
      raise ArgumentError, "Restaurante não encontrado" unless restaurante

      # Busca a catraca e verifica se pertence ao restaurante
      catraca = Catraca.find_by(
        id: @catraca_id,
        restaurante_id: restaurante.id,
        modo_acesso: "fastpass"
      )

      raise ArgumentError, "Catraca FastPass inválida para este restaurante" unless catraca

      # Busca ou cria o sorteio de hoje
      sorteio = Sorteio.find_or_create_by!(data: Date.current) do |s|
        s.status = "aberto"
      end

      @usuario.with_lock do
        # Verifica se já existe inscrição para o mesmo turno
        existente = InscricaoFastpass
          .joins(:time_frame)
          .where(
            usuario_matricula: @usuario.matricula,
            sorteio_id: sorteio.id
          )
          .where(time_frames: { turno_id: time_frame.turno_id })
          .exists?

        if existente
          raise ArgumentError,
            "Você já possui uma inscrição para um horário neste mesmo turno de refeição."
        end

        # Cria a inscrição
        InscricaoFastpass.create!(
          usuario: @usuario,
          sorteio: sorteio,
          time_frame: time_frame,
          catraca: catraca,
          resultado: InscricaoFastpass::RESULTADO_GANHOU,
          status_notificacao: "entregue",
          notificada_em: Time.current
        )
      end
    end
  end
end
#AI: GPT desktop web
#Strategy: Aided on fixing the naming convention problem of files and integrating to new user 

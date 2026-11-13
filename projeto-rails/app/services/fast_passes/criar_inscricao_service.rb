module FastPasses
  class CriarInscricaoService
    def initialize(usuario, time_frame_id, restaurante_id, catraca_id, sorteio_id:)
      @usuario = usuario
      @time_frame_id = time_frame_id
      @restaurante_id = restaurante_id
      @catraca_id = catraca_id
      @sorteio_id = sorteio_id
    end

    def call
      raise ArgumentError, "Inscrição permitida somente para estudantes." unless @usuario&.estudante?
      sorteio = Sorteio.find_by(id: @sorteio_id)
      raise ArgumentError, "Selecione um sorteio configurado." unless sorteio

      sorteio.with_lock do
        unless sorteio.status == "aberto" && sorteio.data >= Date.current
          raise ArgumentError, "Este sorteio não está aberto para inscrições."
        end
        janela = TimeFrame.find_by(id: @time_frame_id)
        restaurante = Restaurante.find_by(id: @restaurante_id)
        raise ArgumentError, "Janela ou restaurante não encontrado." unless janela && restaurante
        cota = sorteio.cotas_do_restaurante(restaurante).fetch(janela.id.to_s, 0)
        raise ArgumentError, "Esta janela não possui vagas configuradas neste restaurante." unless cota.positive?
        catraca = restaurante.catracas.find_by(id: @catraca_id, modo_acesso: "fastpass")
        raise ArgumentError, "Catraca FastPass inválida para este restaurante." unless catraca

        # O sorteio é bloqueado também na execução e na edição das cotas.
        # Assim, uma inscrição não entra depois de a seleção ter sido concluída.
        InscricaoFastpass.create!(usuario: @usuario, sorteio: sorteio, time_frame: janela,
          catraca: catraca, resultado: nil, status_notificacao: "pendente", notificada_em: nil)
      end
    end
  end
end

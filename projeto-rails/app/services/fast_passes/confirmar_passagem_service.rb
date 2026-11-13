module FastPasses
  # Adaptador dos endpoints existentes para a validação e confirmação compartilhadas.
  class ConfirmarPassagemService
    class PassagemNegada < StandardError; end

    def initialize(usuario, catraca_id)
      @usuario = usuario
      @catraca_id = catraca_id
    end

    def call(agora: Time.current)
      raise PassagemNegada, "Acesso permitido somente para estudantes." unless @usuario&.estudante?
      catraca = Catraca.find_by(id: @catraca_id, modo_acesso: "fastpass")
      raise PassagemNegada, "Catraca FastPass inválida." unless catraca

      inscricao = InscricaoFastpass.joins(:sorteio).includes(time_frame: :turno)
        .where(usuario_matricula: @usuario.matricula, catraca: catraca,
          resultado: InscricaoFastpass::RESULTADO_GANHOU,
          sorteios: { data: agora.in_time_zone("America/Sao_Paulo").to_date })
        .find { |item| ValidacaoFastpassService.dentro_da_janela?(item.time_frame, agora) }
      raise PassagemNegada, "Você não possui um FastPass válido nesta catraca e horário." unless inscricao

      resultado = ValidacaoFastpassService.call(usuario: @usuario, catraca: catraca,
        turno: inscricao.time_frame.turno, inscricao: inscricao,
        time_frame: inscricao.time_frame, liberador: LiberadorCatracaMock.new, agora: agora)
      unless resultado.autorizado?
        raise PassagemNegada, "Passagem negada: #{resultado.motivo}."
      end
      ConfirmacaoPassagemFastpassService.call(resultado: resultado, agora: agora)
    rescue ConfirmacaoPassagemFastpassService::PassagemNaoAutorizada,
           ConfirmacaoPassagemFastpassService::PassagemJaConfirmada,
           ConfirmacaoPassagemFastpassService::SaldoInsuficiente => erro
      raise PassagemNegada, "Não foi possível confirmar a passagem: #{erro.class.name.demodulize}."
    end
  end
end

# AI: Codex
# Estratégia: preserva os endpoints existentes usando a validação, o débito e a confirmação compartilhados.

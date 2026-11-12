
module FastPasses
  class ConfirmarPassagemService
    class PassagemNegada < StandardError; end

    FUSO_HORARIO = "America/Sao_Paulo"

    def initialize(usuario, catraca_id)
      @usuario = usuario
      @catraca_id = catraca_id
    end

    def call(agora: Time.current)
      agora_local = agora.in_time_zone(FUSO_HORARIO)
      data_atual = agora_local.to_date
      horario_atual = segundos_do_dia(agora_local)

      @usuario.with_lock do
        unless @usuario.perfil == "estudante"
          raise PassagemNegada, "Acesso permitido somente para estudantes."
        end

        sorteio = Sorteio.find_by(data: data_atual)

        raise PassagemNegada, "Não existe FastPass válido para hoje." unless sorteio

        # 1. Busca todas as inscrições FastPass contempladas do estudante
        inscricoes = InscricaoFastpass
          .includes(:time_frame, :sorteio, catraca: :restaurante)
          .where(
            usuario_matricula: @usuario.matricula,
            sorteio_id: sorteio.id,
            resultado: InscricaoFastpass::RESULTADO_GANHOU
          )

        raise PassagemNegada, "Você não possui um FastPass válido para hoje." if inscricoes.empty?

        # 2. Encontra a inscrição correspondente ao horário atual
        inscricao = inscricoes.find do |item|
          inicio = segundos_do_dia(item.time_frame.inicio)
          fim = segundos_do_dia(item.time_frame.fim)

          horario_atual.between?(inicio, fim)
        end

        unless inscricao
          horarios = inscricoes.map do |item|
            "#{item.time_frame.inicio.strftime('%H:%M')}–#{item.time_frame.fim.strftime('%H:%M')}"
          end

          raise PassagemNegada,
            "Fora do horário permitido. Seus horários FastPass: #{horarios.join(', ')}."
        end

        # 3. Verifica a catraca atribuída
        raise PassagemNegada, "Esta inscrição não possui uma catraca atribuída." unless inscricao.catraca

        if Acesso.exists?(inscricao_fastpass_id: inscricao.id)
          raise PassagemNegada, "Esta inscrição FastPass já foi utilizada."
        end

        catraca = Catraca.find_by(
          id: @catraca_id,
          modo_acesso: "fastpass"
        )

        raise PassagemNegada, "Catraca FastPass inválida." unless catraca

        unless inscricao.catraca_id == catraca.id
          raise PassagemNegada, "Esta não é a catraca atribuída ao seu FastPass."
        end

        # 4. Identifica restaurante, horário e preço
        restaurante = catraca.restaurante
        time_frame = inscricao.time_frame
        turno = time_frame.turno
        preco = turno.preco

        # 5. Verifica o saldo
        if @usuario.saldo < preco
          raise PassagemNegada,
            "Saldo insuficiente. Sua refeição custa R$ #{format('%.2f', preco)}."
        end

        # 6. Registra passagem e movimentações financeiras
        Acesso.transaction do
          restaurante.lock!

          acesso = Acesso.create!(
            usuario: @usuario,
            turno: turno,
            catraca: catraca,
            inscricao_fastpass: inscricao,
            data_hora: agora,
            passagem_em: agora,
            valor_debitado: preco,
            status: "liberado"
          )

          @usuario.update!(saldo: @usuario.saldo - preco)

          restaurante.update!(
            faturamento: restaurante.faturamento + preco
          )

          acesso
        end
      end
    end

    private

    def segundos_do_dia(horario)
      horario.hour * 3600 + horario.min * 60 + horario.sec
    end
  end
end

#AI: GPT desktop web
#Strategy: Asked, through natural language, and providing pertinent files, aid on integrating reports screen
require "bigdecimal"

class ConfirmacaoPassagemFastpassService
  class PassagemNaoAutorizada < StandardError; end
  class PassagemJaConfirmada < StandardError; end
  class SaldoInsuficiente < StandardError; end

  def self.call(resultado:, agora: Time.current)
    raise PassagemNaoAutorizada unless resultado&.autorizado?
    raise PassagemJaConfirmada if resultado.confirmado?

    usuario = resultado.usuario
    valor = resultado.preco

    # with_lock abre uma transacao e relê o saldo antes de efetuar o debito.
    acesso = usuario.with_lock do
      raise SaldoInsuficiente if BigDecimal(usuario.saldo.to_s) < valor

      novo_acesso = Acesso.create!(
        usuario_matricula: usuario.matricula,
        catraca_id: resultado.catraca.id,
        turno_id: resultado.time_frame.turno_id,
        inscricao_fastpass_id: resultado.inscricao.id,
        data_hora: resultado.validado_em,
        passagem_em: agora,
        status: "liberado",
        valor_debitado: valor
      )
      usuario.update!(saldo: BigDecimal(usuario.saldo.to_s) - valor)
      novo_acesso
    end

    resultado.confirmado = true
    resultado.repositorio.registrar(
      catraca_id: resultado.catraca.id,
      usuario_matricula: usuario.matricula,
      status: "Liberado",
      data_hora: agora
    )
    acesso
  end
end

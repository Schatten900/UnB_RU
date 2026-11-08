class ConfirmacaoPassagemFastpassService
  class PassagemNaoAutorizada < StandardError; end
  class PassagemJaConfirmada < StandardError; end
  class SaldoInsuficiente < StandardError; end

  def self.call(resultado:, agora: Time.current)
    raise PassagemNaoAutorizada unless resultado&.autorizado? && resultado.acesso
    raise PassagemJaConfirmada if resultado.confirmado?

    unless resultado.acesso.confirmar_passagem!(agora: agora)
      raise SaldoInsuficiente
    end

    resultado.confirmado = true
    resultado.acesso.reload
  end
end

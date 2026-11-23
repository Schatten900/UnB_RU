class ConfirmacaoPassagemFastpassService
  class PassagemNaoAutorizada < StandardError; end
  class PassagemJaConfirmada < StandardError; end
  class SaldoInsuficiente < StandardError; end

  def self.call(resultado:, agora: Time.current)
    raise PassagemNaoAutorizada unless resultado&.acesso

    resultado.acesso.with_lock do
      raise PassagemJaConfirmada if resultado.confirmado? || resultado.acesso.passagem_em.present?
      unless resultado.autorizado? && resultado.acesso.status == "pendente"
        raise PassagemNaoAutorizada
      end

      unless resultado.acesso.confirmar_passagem!(agora: agora)
        raise SaldoInsuficiente
      end
    end

    resultado.confirmado = true
    resultado.acesso.reload
  end
end

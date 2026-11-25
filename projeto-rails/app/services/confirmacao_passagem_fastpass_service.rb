class ConfirmacaoPassagemFastpassService
  class PassagemNaoAutorizada < StandardError; end
  class PassagemJaConfirmada < StandardError; end
  class SaldoInsuficiente < StandardError; end

  # Confirma o Resultado recebido no horário agora, verificando autorização e saldo.
  # Retorna Acesso ou lança erro; debita e registra a passagem sob bloqueio transacional.
  def self.call(resultado:, agora: Time.current)
    raise PassagemNaoAutorizada unless resultado&.acesso

    resultado.acesso.with_lock do
      validar_tentativa!(resultado)

      unless resultado.acesso.confirmar_passagem!(agora: agora)
        raise SaldoInsuficiente
      end
    end

    resultado.confirmado = true
    resultado.acesso.reload
  end

  # Verifica autorização e confirmação prévia no Resultado recebido.
  # Retorna nil ou lança erro; não altera registros.
  def self.validar_tentativa!(resultado)
    raise PassagemJaConfirmada if resultado.confirmado? || resultado.acesso.passagem_em.present?
    unless resultado.autorizado? && resultado.acesso.status == "pendente"
      raise PassagemNaoAutorizada
    end
  end
  private_class_method :validar_tentativa!

end

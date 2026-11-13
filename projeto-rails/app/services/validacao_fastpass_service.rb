require "bigdecimal"

class ValidacaoFastpassService
  RESULTADOS_VENCEDORES = [InscricaoFastpass::RESULTADO_GANHOU].freeze

  Resultado = Struct.new(:autorizado, :motivo, :acesso, :confirmado, keyword_init: true) do
    def autorizado?
      autorizado == true
    end

    def confirmado?
      confirmado == true
    end
  end

  def self.call(usuario:, catraca:, turno:, inscricao:, time_frame:,
                liberador:, agora: Time.current)
    # O modo normal e tratado pela validacao geral da issue #6.
    unless catraca&.modo_acesso == "fastpass"
      return Resultado.new(autorizado: false, motivo: :modo_nao_fastpass)
    end

    # Acesso exige um usuario existente (FK nao permite tentativas anonimas).
    unless usuario&.persisted?
      return Resultado.new(autorizado: false, motivo: :usuario_invalido)
    end

    valor = BigDecimal(turno.preco.to_s)
    raise ArgumentError, "Preco da refeicao nao pode ser negativo" if valor.negative?

    motivo = motivo_bloqueio(usuario, inscricao, time_frame, valor, agora)
    if motivo.nil? && !liberador.liberar(catraca_id: catraca.id)
      motivo = :falha_liberacao
    end

    # Uma tentativa identificada gera Acesso, mesmo quando foi bloqueada.
    acesso = Acesso.create!(
      usuario: usuario,
      catraca: catraca,
      turno: turno,
      inscricao_fastpass_id: motivo.nil? ? inscricao.id : nil,
      data_hora: agora,
      status: motivo ? "bloqueado" : "pendente",
      passagem_em: nil,
      valor_debitado: 0
    )

    Resultado.new(
      autorizado: motivo.nil?,
      motivo: motivo || :autorizado,
      acesso: acesso,
      confirmado: false
    )
  end

  def self.motivo_bloqueio(usuario, inscricao, time_frame, preco, agora)
    return :usuario_invalido unless usuario
    return :sem_fastpass unless inscricao && time_frame
    return :sem_fastpass unless inscricao.usuario_matricula.to_s == usuario.matricula.to_s
    return :sem_fastpass unless inscricao.time_frame_id == time_frame.id
    return :sem_fastpass unless RESULTADOS_VENCEDORES.include?(inscricao.resultado.to_s.downcase)
    return :fora_da_janela unless dentro_da_janela?(time_frame, agora)
    return :saldo_insuficiente if BigDecimal(usuario.saldo.to_s) < preco

    nil
  end
  private_class_method :motivo_bloqueio

  # Inicio incluido; fim excluido.
  def self.dentro_da_janela?(time_frame, agora)
    return false unless time_frame.inicio && time_frame.fim

    horario = segundos(agora.in_time_zone("America/Sao_Paulo"))
    inicio = segundos(time_frame.inicio)
    fim = segundos(time_frame.fim)

    return false if inicio == fim
    return horario >= inicio && horario < fim if inicio < fim

    horario >= inicio || horario < fim
  end
  private_class_method :dentro_da_janela?

  def self.segundos(horario)
    horario.hour * 3600 + horario.min * 60 + horario.sec
  end
  private_class_method :segundos
end

# AI: Gemini
# Prompt: Modified with Gemini through natural language conversation about fast pass, general idea, models, existing controllers were passed, and then the AI was asked to modify it.
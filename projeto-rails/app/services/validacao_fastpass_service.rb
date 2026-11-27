require 'bigdecimal'

class ValidacaoFastpassService
  RESULTADOS_VENCEDORES = [InscricaoFastpass::RESULTADO_GANHOU].freeze

  Resultado = Struct.new(:autorizado, :motivo, :acesso, :confirmado, keyword_init: true) do
    # Indica se o resultado permite a passagem.
    # Sem argumentos; retorna Boolean e não altera estado.
    def autorizado?
      autorizado == true
    end

    # Indica se o resultado já foi confirmado.
    # Sem argumentos; retorna Boolean e não altera estado.
    def confirmado?
      confirmado == true
    end
  end

  # Valida usuário, inscrição, janela, saldo e catraca para o turno e horário recebidos.
  # Recebe também o liberador simulado; retorna Resultado e registra a tentativa, sem débito.
  def self.call(usuario:, catraca:, turno:, inscricao:, time_frame:,
                liberador:, agora: Time.current)
    # O modo normal e tratado pela validacao geral da issue #6.
    return Resultado.new(autorizado: false, motivo: :modo_nao_fastpass) unless catraca&.modo_acesso == 'fastpass'

    # Acesso exige um usuario existente (FK nao permite tentativas anonimas).
    return Resultado.new(autorizado: false, motivo: :usuario_invalido) unless usuario&.persisted?

    valor = BigDecimal(turno.preco.to_s)
    raise ArgumentError, 'Preco da refeicao nao pode ser negativo' if valor.negative?

    motivo = motivo_bloqueio(usuario, inscricao, time_frame, valor, agora) ||
             motivo_operacao(inscricao, catraca, liberador)
    acesso = registrar_tentativa(usuario, catraca, turno, inscricao, motivo, agora)

    Resultado.new(
      autorizado: motivo.nil?,
      motivo: motivo || :autorizado,
      acesso: acesso,
      confirmado: false
    )
  end

  # Verifica catraca e reutilização da inscrição e solicita a liberação simulada.
  # Recebe inscrição, catraca e liberador; retorna motivo ou nil, consultando o banco.
  def self.motivo_operacao(inscricao, catraca, liberador)
    return :catraca_incorreta if inscricao.catraca_id.present? && inscricao.catraca_id != catraca.id
    return :fastpass_utilizado if inscricao_utilizada?(inscricao)
    return :falha_liberacao unless liberador.liberar(catraca_id: catraca.id)

    nil
  end

  # Verifica se a inscrição recebida já possui passagem confirmada.
  # Retorna Boolean; consulta o banco sem alterar registros.
  def self.inscricao_utilizada?(inscricao)
    Acesso.where(inscricao_fastpass_id: inscricao.id).where.not(passagem_em: nil).exists?
  end

  # Persiste a tentativa com usuário, catraca, turno, inscrição, motivo e horário recebidos.
  # Retorna Acesso; grava a tentativa pendente ou bloqueada, sem débito.
  def self.registrar_tentativa(usuario, catraca, turno, inscricao, motivo, agora)
    Acesso.create!(
      usuario: usuario, catraca: catraca, turno: turno,
      inscricao_fastpass_id: motivo.nil? ? inscricao.id : nil,
      data_hora: agora, status: motivo ? 'bloqueado' : 'pendente',
      passagem_em: nil, valor_debitado: 0
    )
  end
  private_class_method :motivo_operacao, :inscricao_utilizada?, :registrar_tentativa

  # Avalia usuário, inscrição, janela, preço e horário recebidos.
  # Retorna símbolo de bloqueio ou nil; não altera registros.
  def self.motivo_bloqueio(usuario, inscricao, time_frame, preco, agora)
    return :usuario_invalido unless usuario
    return :sem_fastpass unless inscricao_valida?(usuario, inscricao, time_frame)
    return :fora_da_janela unless dentro_da_janela?(time_frame, agora)
    return :saldo_insuficiente if BigDecimal(usuario.saldo.to_s) < preco

    nil
  end
  private_class_method :motivo_bloqueio

  # Compara o usuário, a inscrição vencedora e a janela recebidos.
  # Retorna valor verdadeiro ou falso/nil; não altera registros.
  def self.inscricao_valida?(usuario, inscricao, time_frame)
    inscricao && time_frame &&
      inscricao.usuario_matricula.to_s == usuario.matricula.to_s &&
      inscricao.time_frame_id == time_frame.id &&
      RESULTADOS_VENCEDORES.include?(inscricao.resultado.to_s.downcase)
  end
  private_class_method :inscricao_valida?

  # Inicio incluido; fim excluido.
  # Compara agora com a janela recebida, incluindo o início e excluindo o fim.
  # Retorna Boolean no horário de Brasília; não altera registros.
  def self.dentro_da_janela?(time_frame, agora)
    return false unless time_frame.inicio && time_frame.fim

    horario = segundos(agora.in_time_zone('America/Sao_Paulo'))
    inicio = segundos(time_frame.inicio)
    fim = segundos(time_frame.fim)

    return false if inicio == fim
    return horario >= inicio && horario < fim if inicio < fim

    horario >= inicio || horario < fim
  end

  # Converte o horário recebido em segundos desde meia-noite.
  # Retorna Integer; não modifica o horário.
  def self.segundos(horario)
    (horario.hour * 3600) + (horario.min * 60) + horario.sec
  end
  private_class_method :segundos
end

# AI: Gemini
# Prompt: Modified with Gemini through natural language conversation about fast pass, general idea, models, existing controllers were passed, and then the AI was asked to modify it.

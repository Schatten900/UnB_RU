require "bigdecimal"

class ValidacaoFastpassService
  RESULTADOS_VENCEDORES = %w[ganhou].freeze

  Resultado = Struct.new(
    :autorizado, :motivo, :usuario, :catraca, :inscricao, :time_frame,
    :preco, :validado_em, :repositorio, :confirmado, keyword_init: true
  ) do
    def autorizado?
      autorizado == true
    end

    def confirmado?
      confirmado == true
    end
  end

  def self.call(usuario:, catraca:, inscricao:, time_frame:, preco:,
                repositorio:, liberador:, agora: Time.current)
    # A catraca no modo normal sera tratada pela validacao geral (Issue #6).
    unless catraca&.modo_acesso == "fastpass"
      return Resultado.new(autorizado: false, motivo: :modo_nao_fastpass)
    end

    valor = BigDecimal(preco.to_s)
    raise ArgumentError, "Preco da refeicao deve ser positivo" unless valor.positive?

    motivo = motivo_bloqueio(usuario, inscricao, time_frame, valor, agora)
    if motivo
      registrar_bloqueio(repositorio, catraca, usuario, agora)
      return Resultado.new(autorizado: false, motivo: motivo)
    end

    unless liberador.liberar(catraca_id: catraca.id)
      registrar_bloqueio(repositorio, catraca, usuario, agora)
      return Resultado.new(autorizado: false, motivo: :falha_liberacao)
    end

    Resultado.new(
      autorizado: true, motivo: :autorizado, usuario: usuario,
      catraca: catraca, inscricao: inscricao, time_frame: time_frame,
      preco: valor, validado_em: agora, repositorio: repositorio,
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

  # Horario inicial incluido; horario final excluido (12:30:00 nao pertence a 12:15-12:30).
  def self.dentro_da_janela?(time_frame, agora)
    return false unless time_frame.inicio && time_frame.fim

    horario = segundos(agora.in_time_zone("America/Sao_Paulo"))
    inicio = segundos(time_frame.inicio)
    fim = segundos(time_frame.fim)

    return false if inicio == fim
    return horario >= inicio && horario < fim if inicio < fim

    horario >= inicio || horario < fim # Tambem aceita janela que atravessa meia-noite.
  end
  private_class_method :dentro_da_janela?

  def self.segundos(horario)
    horario.hour * 3600 + horario.min * 60 + horario.sec
  end
  private_class_method :segundos

  def self.registrar_bloqueio(repositorio, catraca, usuario, agora)
    repositorio.registrar(
      catraca_id: catraca.id,
      usuario_matricula: usuario&.matricula,
      status: "Bloqueado",
      data_hora: agora
    )
  end
  private_class_method :registrar_bloqueio
end

# Simula leituras com estudantes e inscrições existentes
#
# A matricula informada tem prioridade sobre a seleção automática do cenário
class SimulacaoTerminalService
  Resultado = Struct.new(:validacao, :modo, :janela, :origem_leitura, keyword_init: true)
  MODOS = %w[normal fastpass].freeze
  CENARIOS = %w[ok fora_janela sem_saldo modo_comum].freeze

  # Executa a simulação e retorna um Resultado com validação, modo, janela e origem
  #
  # Argumentos:
  # - +catraca+: catraca configurada no terminal
  # - +turno+: turno usado na consulta de inscrições do fastpass
  # - +modo+: "normal" ou "fastpass" e pode ser ajustado pelo cenário
  # - +cenario+: "ok", "fora_janela", "sem_saldo" ou "modo_comum"
  # - +matricula+: identificação opcional; sem ela, seleciona um candidato
  # - +agora+: instante da leitura
  #
  # Lança ArgumentError para parâmetros inválidos ou ausência de candidato
  def self.call(catraca:, turno:, modo:, cenario:, matricula: nil, agora: Time.current)
    validar_parametros!(modo, cenario, turno)
    modo = modo_do_cenario(modo, cenario)
    agora = agora.in_time_zone("America/Sao_Paulo")
    matricula = matricula.to_s.strip
    estudante, inscricao = localizar_leitura(turno, modo, cenario, matricula, agora)
    validar_estudante_encontrado!(estudante)

    Acesso.transaction do
      montar_resultado(estudante, inscricao, catraca, turno, modo, matricula, agora)
    end
  end

  # Valida modo, cenário e tarifa positiva
  def self.validar_parametros!(modo, cenario, turno)
    raise ArgumentError, "Modo inválido." unless MODOS.include?(modo)
    raise ArgumentError, "Cenário inválido." unless CENARIOS.include?(cenario)
    raise ArgumentError, "Configure um turno com tarifa positiva para simular." unless turno&.preco&.positive?
  end
  private_class_method :validar_parametros!

  # Retorna o modo exigido pelo cenário ou preserva o +modo+ recebido
  def self.modo_do_cenario(modo, cenario)
    return "fastpass" if cenario == "fora_janela"
    return "normal" if cenario == "modo_comum"

    modo
  end
  private_class_method :modo_do_cenario

  # Lança ArgumentError quando a seleção não encontra um estudante compatível
  def self.validar_estudante_encontrado!(estudante)
    return if estudante

    raise ArgumentError, "Nenhum estudante cadastrado atende ao cenário. Verifique saldo, inscrição e janela FastPass do turno."
  end
  private_class_method :validar_estudante_encontrado!

  # Registra a tentativa e monta o Resultado, sem confirmar nem debitar a passagem
  #
  # +matricula+ determina a origem "informada" ou "automatica"
  # A janela é nil no modo normal
  def self.montar_resultado(estudante, inscricao, catraca, turno, modo, matricula, agora)
    if modo == "fastpass"
      janela = inscricao&.time_frame
      validacao = validar_fastpass(estudante, inscricao, catraca, turno, janela, agora)
    else
      validacao = registrar_acesso_normal(estudante, catraca, turno, agora)
    end

    Resultado.new(validacao: validacao, modo: modo, janela: janela,
      origem_leitura: matricula.present? ? "informada" : "automatica")
  end
  private_class_method :montar_resultado

  # Delega a validação FastPass e preserva a inscrição nas tentativas bloqueadas.
  #
  # Ajusta a modalidade da catraca em memória, sem salvar sua configuração.
  # Retorna o resultado fornecido pelo ValidacaoFastpassService.
  def self.validar_fastpass(estudante, inscricao, catraca, turno, janela, agora)
    # O toggle afeta somente esta leitura; não reconfigura a catraca no banco.
    catraca.modo_acesso = "fastpass"
    validacao = ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, turno: turno,
      inscricao: inscricao, time_frame: janela,
      liberador: LiberadorCatracaMock.new, agora: agora
    )
    # Preserva a modalidade também no registro de uma tentativa bloqueada.
    validacao.acesso.update!(inscricao_fastpass_id: inscricao.id) if inscricao
    validacao
  end
  private_class_method :validar_fastpass

  # Registra acesso normal pendente ou bloqueado conforme o saldo do estudante.
  #
  # Retorna uma validação não confirmada, sem débito e com valor debitado zero.
  def self.registrar_acesso_normal(estudante, catraca, turno, agora)
    autorizado = estudante.saldo_suficiente_para?(turno)
    acesso = Acesso.create!(
      usuario: estudante, catraca: catraca, turno: turno, data_hora: agora,
      status: autorizado ? "pendente" : "bloqueado", valor_debitado: 0
    )
    validacao = ValidacaoFastpassService::Resultado.new(
      autorizado: autorizado, motivo: autorizado ? :autorizado : :saldo_insuficiente,
      acesso: acesso, confirmado: false
    )
  end
  private_class_method :registrar_acesso_normal

  # Retorna [Usuario, InscricaoFastpass], priorizando a matrícula informada.
  #
  # Na seleção automática normal, a inscrição é nil
  def self.localizar_leitura(turno, modo, cenario, matricula, agora)
    return localizar_por_matricula(matricula, turno, agora) if matricula.present?
    return [selecionar_estudante_normal(turno, cenario), nil] if modo == "normal"

    inscricao = selecionar_inscricao_fastpass(turno, cenario, agora)
    [inscricao&.usuario, inscricao]
  end
  private_class_method :localizar_leitura

  # Retorna estudantes, excluindo matrículas reservadas a funcionários/admin
  def self.estudantes_cadastrados()
    Usuario.where(perfil: "estudante").where.not("matricula LIKE ?", "999%")
  end
  private_class_method :estudantes_cadastrados

  # Retorna inscrições contempladas da data de +agora+ e do +turno+, por ID
  def self.inscricoes_do_turno(turno, agora)
    InscricaoFastpass.joins(:sorteio, :time_frame, :usuario)
                                 .where(resultado: InscricaoFastpass::RESULTADO_GANHOU,
                                        sorteios: { data: agora.to_date },
                                        time_frames: { turno_id: turno.id },
                                        usuarios: { perfil: "estudante" })
                                 .includes(:usuario, :time_frame).order(:id)
  end
  private_class_method :inscricoes_do_turno

  # Busca a matrícula exata e sua inscrição, priorizando a janela atual.
  #
  # Retorna [Usuario, InscricaoFastpass], com inscrição possivelmente nil
  def self.localizar_por_matricula(matricula, turno, agora)
    estudante = estudantes_cadastrados.find_by(matricula: matricula)
    raise ArgumentError, "Não existe estudante cadastrado com a matrícula lida." unless estudante

    candidatas = inscricoes_do_turno(turno, agora).where(usuario_matricula: estudante.matricula).to_a
    inscricao = candidatas.find do |item|
      ValidacaoFastpassService.dentro_da_janela?(item.time_frame, agora)
    end || candidatas.first
    [estudante, inscricao]
  end
  private_class_method :localizar_por_matricula

  # Retorna o primeiro estudante por matrícula cujo saldo corresponde ao cenário.
  def self.selecionar_estudante_normal(turno, cenario)
    estudantes_cadastrados.where("saldo #{comparacao_saldo(cenario)} ?", turno.preco)
      .order(:matricula).first
  end
  private_class_method :selecionar_estudante_normal

  # Retorna a primeira inscrição compatível com saldo e janela, ou nil.
  def self.selecionar_inscricao_fastpass(turno, cenario, agora)
    inscricoes_do_turno(turno, agora)
      .where("usuarios.saldo #{comparacao_saldo(cenario)} ?", turno.preco)
      .detect { |item| candidato_fastpass?(item, cenario, agora) }
  end
  private_class_method :selecionar_inscricao_fastpass

  # Indica se a inscrição pertence a estudante e atende à janela do cenário.
  #
  # "fora_janela" exige estar fora do intervalo; os demais cenários, dentro.
  def self.candidato_fastpass?(inscricao, cenario, agora)
    dentro = ValidacaoFastpassService.dentro_da_janela?(inscricao.time_frame, agora)
    inscricao.usuario.estudante? && (cenario == "fora_janela" ? !dentro : dentro)
  end
  private_class_method :candidato_fastpass?

  # Retorna um operador SQL fixo para selecionar saldo insuficiente ou suficiente.
  def self.comparacao_saldo(cenario)
    cenario == "sem_saldo" ? "<" : ">="
  end
  private_class_method :comparacao_saldo
end

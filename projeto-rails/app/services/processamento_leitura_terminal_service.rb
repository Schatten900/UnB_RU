# Processa uma matrícula informada no terminal sem selecionar cenários de simulação.
class ProcessamentoLeituraTerminalService
  Resultado = Struct.new(:validacao, :modo, :janela, keyword_init: true)
  MODOS = %w[normal fastpass].freeze

  # Registra uma leitura normal ou FastPass, sem confirmar ou debitar a passagem.
  #
  # +matricula+ é obrigatória e deve identificar um estudante cadastrado.
  # Retorna o resultado da validação; entradas inválidas geram ArgumentError.
  def self.call(catraca:, turno:, modo:, matricula:, agora: Time.current)
    matricula = matricula.to_s.strip
    validar_entrada!(matricula, modo, turno)

    estudante = localizar_estudante(matricula)
    agora = agora.in_time_zone('America/Sao_Paulo')
    Acesso.transaction do
      if modo == 'fastpass'
        processar_fastpass(estudante, catraca, turno, agora)
      else
        validacao = registrar_acesso_normal(estudante, catraca, turno, agora)
        Resultado.new(validacao: validacao, modo: modo)
      end
    end
  end

  # Rejeita matrícula ausente, modalidade desconhecida e turno sem tarifa positiva.
  def self.validar_entrada!(matricula, modo, turno)
    raise ArgumentError, 'Informe a matrícula recebida na leitura.' if matricula.blank?
    raise ArgumentError, 'Modo inválido.' unless MODOS.include?(modo)
    return if turno&.preco&.positive?

    raise ArgumentError,
          'Configure um turno com tarifa positiva para processar a leitura.'
  end
  private_class_method :validar_entrada!

  # Localiza exclusivamente o estudante identificado pela matrícula informada.
  def self.localizar_estudante(matricula)
    estudante = Usuario.find_by(matricula: matricula, perfil: 'estudante')
    raise ArgumentError, 'Não existe estudante cadastrado com a matrícula lida.' unless estudante&.estudante?

    estudante
  end
  private_class_method :localizar_estudante

  # Valida o FastPass real e preserva a inscrição no registro de tentativa bloqueada.
  def self.processar_fastpass(estudante, catraca, turno, agora)
    inscricao = localizar_inscricao(estudante, turno, agora)
    janela = inscricao&.time_frame
    # A modalidade selecionada vale para a leitura, sem alterar a configuração salva.
    catraca.modo_acesso = 'fastpass'
    validacao = ValidacaoFastpassService.call(
      usuario: estudante, catraca: catraca, turno: turno,
      inscricao: inscricao, time_frame: janela,
      liberador: LiberadorCatracaMock.new, agora: agora
    )
    validacao.acesso.update!(inscricao_fastpass_id: inscricao.id) if inscricao

    Resultado.new(validacao: validacao, modo: 'fastpass', janela: janela)
  end
  private_class_method :processar_fastpass

  # Busca uma inscrição contemplada da data e turno, priorizando a janela atual.
  def self.localizar_inscricao(estudante, turno, agora)
    inscricoes = InscricaoFastpass.joins(:sorteio, :time_frame)
                                  .where(usuario_matricula: estudante.matricula,
                                         resultado: InscricaoFastpass::RESULTADO_GANHOU,
                                         sorteios: { data: agora.to_date }, time_frames: { turno_id: turno.id })
                                  .includes(:time_frame).order(:id).to_a

    inscricoes.find { |item| ValidacaoFastpassService.dentro_da_janela?(item.time_frame, agora) } || inscricoes.first
  end
  private_class_method :localizar_inscricao

  # Registra a tentativa normal e verifica o saldo sem efetuar débito.
  def self.registrar_acesso_normal(estudante, catraca, turno, agora)
    autorizado = estudante.saldo_suficiente_para?(turno)
    acesso = Acesso.create!(usuario: estudante, catraca: catraca, turno: turno,
                            data_hora: agora, status: autorizado ? 'pendente' : 'bloqueado', valor_debitado: 0)

    ValidacaoFastpassService::Resultado.new(
      autorizado: autorizado, motivo: autorizado ? :autorizado : :saldo_insuficiente,
      acesso: acesso, confirmado: false
    )
  end
  private_class_method :registrar_acesso_normal
end

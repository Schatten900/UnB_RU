class SimulacaoTerminalService
  Resultado = Struct.new(:validacao, :modo, :janela, :origem_leitura, keyword_init: true)
  MODOS = %w[normal fastpass].freeze
  CENARIOS = %w[ok fora_janela sem_saldo modo_comum].freeze

  def self.call(catraca:, turno:, modo:, cenario:, matricula: nil, agora: Time.current)
    raise ArgumentError, "Modo inválido." unless MODOS.include?(modo)
    raise ArgumentError, "Cenário inválido." unless CENARIOS.include?(cenario)
    raise ArgumentError, "Configure um turno com tarifa positiva para simular." unless turno&.preco&.positive?

    modo = "fastpass" if cenario == "fora_janela"
    modo = "normal" if cenario == "modo_comum"
    agora = agora.in_time_zone("America/Sao_Paulo")

    matricula = matricula.to_s.strip
    estudante, inscricao = localizar_leitura(turno, modo, cenario, matricula, agora)
    raise ArgumentError, "Nenhum estudante cadastrado atende ao cenário. Verifique saldo, inscrição e janela FastPass do turno." unless estudante

    Acesso.transaction do
      if modo == "fastpass"
        janela = inscricao&.time_frame

        # O toggle afeta somente esta leitura; não reconfigura a catraca no banco.
        catraca.modo_acesso = modo
        validacao = ValidacaoFastpassService.call(
          usuario: estudante, catraca: catraca, turno: turno,
          inscricao: inscricao, time_frame: janela,
          liberador: LiberadorCatracaMock.new, agora: agora
        )
        # Preserva a modalidade também no registro de uma tentativa bloqueada.
        validacao.acesso.update!(inscricao_fastpass_id: inscricao.id) if inscricao
      else
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

      Resultado.new(
        validacao: validacao, modo: modo, janela: janela,
        origem_leitura: matricula.present? ? "informada" : "automatica"
      )
    end
  end

  def self.localizar_leitura(turno, modo, cenario, matricula, agora)
    estudantes = Usuario.where(perfil: "estudante").where.not("matricula LIKE ?", "999%")
    inscricoes = InscricaoFastpass.joins(:sorteio, :time_frame, :usuario)
                                 .where(resultado: InscricaoFastpass::RESULTADO_GANHOU,
                                        sorteios: { data: agora.to_date },
                                        time_frames: { turno_id: turno.id },
                                        usuarios: { perfil: "estudante" })
                                 .includes(:usuario, :time_frame).order(:id)

    if matricula.present?
      estudante = estudantes.find_by(matricula: matricula)
      raise ArgumentError, "Não existe estudante cadastrado com a matrícula lida." unless estudante

      # Uma leitura informada é validada pelos dados reais, sem forçar o cenário do botão.
      candidatas = inscricoes.where(usuario_matricula: estudante.matricula).to_a
      inscricao = candidatas.find { |item| ValidacaoFastpassService.dentro_da_janela?(item.time_frame, agora) } || candidatas.first
      return [estudante, inscricao]
    end

    comparacao = cenario == "sem_saldo" ? "<" : ">="
    if modo == "normal"
      return [estudantes.where("saldo #{comparacao} ?", turno.preco).order(:matricula).first, nil]
    end

    inscricao = inscricoes.where("usuarios.saldo #{comparacao} ?", turno.preco).detect do |item|
      dentro = ValidacaoFastpassService.dentro_da_janela?(item.time_frame, agora)
      item.usuario.estudante? && (cenario == "fora_janela" ? !dentro : dentro)
    end
    [inscricao&.usuario, inscricao]
  end
  private_class_method :localizar_leitura
end

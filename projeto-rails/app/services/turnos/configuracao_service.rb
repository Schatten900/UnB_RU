module Turnos
  class ConfiguracaoService
    class JanelasComInscricoes < StandardError; end

    DURACAO_MAXIMA = 120
    HORARIO_VALIDO = /\A(?:[01]\d|2[0-3]):[0-5]\d(?::00(?:\.0+)?)?\z/

    # Cria o turno com os atributos e a duração de intervalo recebidos.
    # Retorna Turno ou lança erro de validação; grava turno e janelas em transação.
    def self.criar(atributos:, duracao_intervalo:)
      dados = atributos.to_h.symbolize_keys
      duracao = validar!(dados, duracao_intervalo)

      Turno.transaction do
        turno = Turno.create!(dados)
        GerarTimeframe.new(turno, duracao).call
        turno
      end
    end

    # Atualiza turno e janelas conforme atributos e duração recebidos.
    # Retorna Turno ou lança erro; grava em transação, preservando janelas com inscrições.
    def self.atualizar(turno:, atributos:, duracao_intervalo:)
      dados = atributos.to_h.symbolize_keys
      duracao = validar!(dados, duracao_intervalo)

      regenerar = regenerar_janelas?(turno, dados, duracao)
      exigir_janelas_sem_inscricoes!(turno) if regenerar

      Turno.transaction do
        turno.update!(dados)
        GerarTimeframe.new(turno, duracao).call if regenerar
        turno
      end
    end

    # Calcula a duração em minutos da primeira janela do turno recebido.
    # Retorna Integer, usando 15 como padrão; consulta o banco sem gravar.
    def self.duracao_atual(turno)
      primeira = turno.time_frames.order(:inicio, :id).first
      return 15 unless primeira

      minutos = ((primeira.fim - primeira.inicio) / 60).round
      minutos.positive? ? minutos : 15
    end

    # Valida horários dos dados recebidos e a duração do intervalo.
    # Retorna a duração inteira ou lança ArgumentError; normaliza dados em memória.
    def self.validar!(dados, duracao_intervalo)
      normalizar_horarios!(dados)
      duracao = Integer(duracao_intervalo.to_s, 10)
      unless duracao.between?(1, DURACAO_MAXIMA)
        raise ArgumentError, "A duracao das janelas deve estar entre 1 e 120 minutos."
      end

      duracao
    rescue TypeError, ArgumentError => erro
      raise erro if erro.message.start_with?("Informe horarios", "A duracao")

      raise ArgumentError, "A duracao das janelas deve ser um numero inteiro de minutos."
    end

    # Valida e normaliza os horários do Hash dados recebido para HH:MM.
    # Retorna nil ou lança ArgumentError; modifica apenas o Hash recebido.
    def self.normalizar_horarios!(dados)
      inicio = dados[:inicio].to_s
      fim = dados[:fim].to_s
      unless HORARIO_VALIDO.match?(inicio) && HORARIO_VALIDO.match?(fim)
        raise ArgumentError, "Informe horarios validos, com o fim posterior ao inicio."
      end
      dados[:inicio] = inicio[0, 5]
      dados[:fim] = fim[0, 5]
      unless dados[:inicio] < dados[:fim]
        raise ArgumentError, "Informe horarios validos, com o fim posterior ao inicio."
      end
    end

    # Compara o turno com os dados e a duração recebidos.
    # Retorna Boolean; consulta as janelas sem alterar registros.
    def self.regenerar_janelas?(turno, dados, duracao)
      turno.time_frames.empty? ||
        turno.inicio.strftime("%H:%M") != dados.fetch(:inicio) ||
        turno.fim.strftime("%H:%M") != dados.fetch(:fim) ||
        duracao_atual(turno) != duracao
    end

    # Impede a regeneração de janelas inscritas no turno recebido.
    # Retorna nil ou lança JanelasComInscricoes; consulta o banco sem gravar.
    def self.exigir_janelas_sem_inscricoes!(turno)
      return unless InscricaoFastpass.where(time_frame_id: turno.time_frames.select(:id)).exists?

      raise JanelasComInscricoes,
            "Este turno possui inscricoes FastPass. Mantenha os horarios e as janelas atuais."
    end

    private_class_method :validar!, :normalizar_horarios!, :regenerar_janelas?, :exigir_janelas_sem_inscricoes!
  end
end

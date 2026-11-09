module Turnos
  class ConfiguracaoService
    class JanelasComInscricoes < StandardError; end

    DURACAO_MAXIMA = 120
    HORARIO_VALIDO = /\A(?:[01]\d|2[0-3]):[0-5]\d(?::00(?:\.0+)?)?\z/

    def self.criar(atributos:, duracao_intervalo:)
      dados = atributos.to_h.symbolize_keys
      duracao = validar!(dados, duracao_intervalo)

      Turno.transaction do
        turno = Turno.create!(dados)
        GerarTimeframe.new(turno, duracao).call
        turno
      end
    end

    def self.atualizar(turno:, atributos:, duracao_intervalo:)
      dados = atributos.to_h.symbolize_keys
      duracao = validar!(dados, duracao_intervalo)

      # Nao apagar time-frames vinculados a inscricoes do FastPass.
      regenerar = turno.time_frames.empty? ||
        turno.inicio.strftime("%H:%M") != dados.fetch(:inicio) ||
        turno.fim.strftime("%H:%M") != dados.fetch(:fim) ||
        duracao_atual(turno) != duracao

      if regenerar && InscricaoFastpass.where(time_frame_id: turno.time_frames.select(:id)).exists?
        raise JanelasComInscricoes,
              "Este turno possui inscricoes FastPass. Mantenha os horarios e as janelas atuais."
      end

      Turno.transaction do
        turno.update!(dados)
        GerarTimeframe.new(turno, duracao).call if regenerar
        turno
      end
    end

    def self.duracao_atual(turno)
      primeira = turno.time_frames.order(:inicio, :id).first
      return 15 unless primeira

      minutos = ((primeira.fim - primeira.inicio) / 60).round
      minutos.positive? ? minutos : 15
    end

    def self.validar!(dados, duracao_intervalo)
      inicio = dados[:inicio].to_s
      fim = dados[:fim].to_s

      unless HORARIO_VALIDO.match?(inicio) && HORARIO_VALIDO.match?(fim)
        raise ArgumentError, "Informe horarios validos, com o fim posterior ao inicio."
      end

      # O campo time do Rails pode enviar HH:MM ou HH:MM:00.
      dados[:inicio] = inicio[0, 5]
      dados[:fim] = fim[0, 5]
      unless dados[:inicio] < dados[:fim]
        raise ArgumentError, "Informe horarios validos, com o fim posterior ao inicio."
      end

      duracao = Integer(duracao_intervalo.to_s, 10)
      unless duracao.between?(1, DURACAO_MAXIMA)
        raise ArgumentError, "A duracao das janelas deve estar entre 1 e 120 minutos."
      end

      duracao
    rescue TypeError, ArgumentError => erro
      raise erro if erro.message.start_with?("Informe horarios", "A duracao")

      raise ArgumentError, "A duracao das janelas deve ser um numero inteiro de minutos."
    end
    private_class_method :validar!
  end
end

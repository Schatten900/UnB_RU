
module Turnos
  class GerarTimeFrames
    def initialize(turno, duracao)
      @turno = turno
      @duracao = duracao.to_i
    end

    def call
      raise ArgumentError unless @duracao.positive?

      @turno.transaction do
        @turno.time_frames.destroy_all

        horario_atual = @turno.inicio

        while horario_atual < @turno.fim
          proximo_horario = [
            horario_atual + @duracao.minutes,
            @turno.fim
          ].min

          @turno.time_frames.create!(
            inicio: horario_atual,
            fim: proximo_horario
          )

          horario_atual = proximo_horario
        end
      end
    end
  end
end
#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb

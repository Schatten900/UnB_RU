class CardapioServices

    # Adquire o turno vinculado ao  horario 
    def self.call(now: Time.current)
        horario_local = now.in_time_zone("America/Sao_Paulo")
        horario_atual = horario_local.seconds_since_midnight
        turno = Turno.order(:inicio).detect do |opcao_turno|
            inicio = opcao_turno.inicio.seconds_since_midnight
            fim = opcao_turno.fim.seconds_since_midnight

            if inicio <= fim
                horario_atual >= inicio && horario_atual < fim
            else
                horario_atual >= inicio || horario_atual < fim
            end
        end

        return nil unless turno

        # Retorna o cardapio que esteja vinculado ao turno do horario
        Cardapio.find_by(
            turno_id: turno.id,
            data: horario_local.to_date
        )
    end
end
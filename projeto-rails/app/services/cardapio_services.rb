class CardapioServices

    # Adquire o turno vinculado ao  horario 
    def self.call(now: Time.current)
        horario_atual = now.strftime("%H:%M:%S")

        turno = Turno
        .where("inicio <= :hora AND fim > :hora", hora: horario_atual)
        .first

        return nil unless turno

        # Retorna o cardapio que esteja vinculado ao turno do horario
        Cardapio.find_by(
            turno_id: turno.id,
            data: now.to_date
        )
    end
end
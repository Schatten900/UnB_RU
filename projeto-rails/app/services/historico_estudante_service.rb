class HistoricoEstudanteService
  ZONA = "America/Sao_Paulo".freeze

  def self.call(usuario:, filtros: {}, agora: Time.current)
    filtros = filtros.to_h.stringify_keys
    acessos = usuario.historico_refeicoes.includes(:turno, catraca: :restaurante)
    recargas = usuario.extrato_recargas.concluida
    agora = agora.in_time_zone(ZONA)

    if filtros["mes_referencia"].present?
      referencia = filtros["mes_referencia"]
      raise ArgumentError, "Mês inválido. Use AAAA-MM." unless referencia.match?(/\A\d{4}-\d{2}\z/)

      data = Date.strptime(referencia, "%Y-%m")
      inicio = data.in_time_zone(ZONA)
      intervalo = inicio...data.next_month.in_time_zone(ZONA)
    else
      inicio = case filtros["periodo"]
      when "todos" then nil
      when "mes" then agora.beginning_of_month
      else (agora - 29.days).beginning_of_day
      end
      intervalo = inicio..agora if inicio
    end

    if intervalo
      acessos = acessos.where(passagem_em: intervalo)
      recargas = recargas.where(data_hora: intervalo)
    end

    registros = acessos.map do |acesso|
      {
        id: "acesso-#{acesso.id}", data_hora: acesso.passagem_em,
        tipo: "refeicao", nome: acesso.turno.nome, turno_id: acesso.turno_id,
        restaurante_id: acesso.catraca.restaurante_id,
        local: "#{acesso.catraca.restaurante.nome} · Piso #{acesso.catraca.piso}",
        detalhe: "Catraca #{acesso.catraca_id} · #{acesso.status.humanize}",
        metodo: acesso.inscricao_fastpass_id ? "fastpass" : "comum",
        metodo_nome: acesso.inscricao_fastpass_id ? "FastPass" : "Comum",
        valor: acesso.valor_debitado
      }
    end
    registros.concat(recargas.map do |recarga|
      {
        id: "recarga-#{recarga.id}", data_hora: recarga.data_hora,
        tipo: "recarga", nome: "Recarga de Saldo",
        local: recarga.pix? ? "Pagamento via PIX" : "Pagamento via cartão",
        detalhe: "Recarga concluída", metodo: recarga.metodo,
        metodo_nome: recarga.pix? ? "PIX" : "Cartão de crédito", valor: recarga.valor
      }
    end)
    registros.select! { |item| item[:tipo] == "recarga" } if filtros["evento"] == "recarga"
    if filtros["evento"].to_s.start_with?("turno:")
      registros.select! { |item| item[:turno_id].to_s == filtros["evento"].delete_prefix("turno:") }
    end
    if filtros["restaurante_id"].present?
      registros.select! { |item| item[:restaurante_id].to_s == filtros["restaurante_id"] }
    end
    if filtros["metodo"].present?
      registros.select! { |item| item[:metodo] == filtros["metodo"] }
    end
    registros.sort_by { |item| [item[:data_hora], item[:id]] }.reverse
  end
end

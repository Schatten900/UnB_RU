class ExtratoRefeicoesService
  FILTROS = %w[periodo evento restaurante_id metodo].freeze
  METODOS = %w[comum fastpass pix cartao_credito].freeze
  REFEICOES = {
    "cafe_da_manha" => %w[cafe_da_manha],
    "almoco" => %w[almoco],
    "jantar" => %w[jantar]
  }.freeze
  Resultado = Struct.new(:lancamentos, :resumo, :filtros, keyword_init: true)

  def self.call(usuario:, filtros: {}, agora: Time.current)
    raise ArgumentError, "Estudante não informado." unless usuario&.matricula.present?

    filtros = normalizar_filtros(filtros)
    agora = agora.in_time_zone("America/Sao_Paulo")
    acessos = usuario.historico_refeicoes.includes(catraca: :restaurante)
    recargas = usuario.extrato_recargas.concluida
    mes = agora.beginning_of_month..agora
    resumo = {
      gasto_mes: acessos.where(passagem_em: mes).sum(:valor_debitado),
      refeicoes_mes: acessos.where(passagem_em: mes).count,
      recarga_mes: recargas.where(data_hora: mes).sum(:valor),
      quantidade_recargas_mes: recargas.where(data_hora: mes).count
    }

    inicio = case filtros["periodo"]
    when "30" then (agora - 29.days).beginning_of_day
    when "mes" then agora.beginning_of_month
    end
    if inicio
      acessos = acessos.where(passagem_em: inicio..agora)
      recargas = recargas.where(data_hora: inicio..agora)
    end

    if REFEICOES.key?(filtros["evento"])
      nomes = REFEICOES.fetch(filtros["evento"])
      turnos = Turno.all.select { |turno| nomes.include?(turno.nome.parameterize(separator: "_")) }
      acessos = acessos.where(turno_id: turnos.map(&:id))
      recargas = recargas.none
    elsif filtros["evento"] == "recarga"
      acessos = acessos.none
    elsif filtros["evento"] == "refeicao"
      recargas = recargas.none
    elsif filtros["evento"].to_s.start_with?("turno:")
      acessos = acessos.where(turno_id: filtros["evento"].delete_prefix("turno:"))
      recargas = recargas.none
    end

    if filtros["restaurante_id"].present?
      acessos = acessos.joins(:catraca).where(catracas: { restaurante_id: filtros["restaurante_id"] })
      recargas = recargas.none
    end

    case filtros["metodo"]
    when "comum"
      acessos = acessos.where(inscricao_fastpass_id: nil)
      recargas = recargas.none
    when "fastpass"
      acessos = acessos.where.not(inscricao_fastpass_id: nil)
      recargas = recargas.none
    when "pix", "cartao_credito"
      recargas = recargas.where(metodo: filtros["metodo"])
      acessos = acessos.none
    end

    lancamentos = acessos.map { |acesso| lancamento_refeicao(acesso) }
    lancamentos.concat(recargas.map { |recarga| lancamento_recarga(recarga) })
    lancamentos.sort_by! { |item| [item[:data_hora], item[:tipo], item[:registro_id]] }.reverse!
    Resultado.new(lancamentos: lancamentos, resumo: resumo, filtros: filtros)
  end

  def self.lancamento_refeicao(acesso)
    {
      id: "acesso-#{acesso.id}", registro_id: acesso.id, data_hora: acesso.passagem_em,
      tipo: "refeicao", nome: acesso.turno.nome, turno_id: acesso.turno_id,
      restaurante_id: acesso.catraca.restaurante_id,
      local: "#{acesso.catraca.restaurante.nome} · Piso #{acesso.catraca.piso}",
      detalhe: "Catraca #{acesso.catraca_id} · #{acesso.status.humanize}",
      metodo: acesso.inscricao_fastpass_id ? "fastpass" : "comum",
      metodo_nome: acesso.inscricao_fastpass_id ? "FastPass" : "Comum",
      valor: acesso.valor_debitado
    }
  end

  def self.lancamento_recarga(recarga)
    {
      id: "recarga-#{recarga.id}", registro_id: recarga.id, data_hora: recarga.data_hora,
      tipo: "recarga", nome: "Recarga de Saldo",
      local: recarga.pix? ? "Pagamento via PIX" : "Pagamento via cartão",
      detalhe: "Recarga concluída", metodo: recarga.metodo,
      metodo_nome: recarga.pix? ? "PIX" : "Cartão de crédito", valor: recarga.valor
    }
  end

  def self.normalizar_filtros(filtros)
    dados = filtros.to_h.stringify_keys.slice(*FILTROS).transform_values { |valor| valor.to_s.strip }.reject { |_, valor| valor.blank? }
    dados["periodo"] = dados["periodo"].presence_in(%w[30 mes todos]) || "30"
    if dados["evento"].present? && !REFEICOES.key?(dados["evento"]) && !%w[recarga refeicao].include?(dados["evento"]) && !/\Aturno:[1-9]\d*\z/.match?(dados["evento"])
      raise ArgumentError, "Selecione uma refeição válida."
    end
    if dados["restaurante_id"].present? && !/\A[1-9]\d*\z/.match?(dados["restaurante_id"])
      raise ArgumentError, "Selecione um restaurante válido."
    end
    if dados["metodo"].present? && !METODOS.include?(dados["metodo"])
      raise ArgumentError, "Selecione um método válido."
    end
    dados
  end
end
